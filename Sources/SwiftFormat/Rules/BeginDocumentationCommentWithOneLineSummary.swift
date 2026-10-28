//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import Markdown
import SwiftSyntax

#if os(macOS)
import NaturalLanguage
#endif

/// All documentation comments must begin with a one-line summary of the declaration.
///
/// Lint: If a comment does not begin with a single-line summary, a lint error is raised.
@_spi(Rules)
public final class BeginDocumentationCommentWithOneLineSummary: SyntaxLintRule {

  /// Unit tests can testably import this module and set this to true in order to force the rule
  /// to use the fallback (simple period separator) mode instead of the `NSLinguisticTag` mode,
  /// even on platforms that support the latter (currently only Apple OSes).
  ///
  /// This allows test runs on those platforms to test both implementations.
  public static var _forcesFallbackModeForTesting = false

  /// Identifies this rule as being opt-in. Well written docs on declarations are important, but
  /// this rule isn't linguistically advanced enough on all platforms to be applied universally.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .visitChildren
  }

  public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .visitChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  public override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseDocComments(in: DeclSyntax(node))
    return .skipChildren
  }

  /// Diagnose documentation comments that don't start with one sentence summary.
  private func diagnoseDocComments(in decl: DeclSyntax) {
    // Extract the summary from a documentation comment, if it exists, and strip
    // out any inline code segments (which shouldn't be considered when looking
    // for the end of a sentence).
    var inlineCodeRemover = InlineCodeRemover()
    guard
      let docComment = DocumentationComment(extractedFrom: decl),
      let briefSummary = docComment.briefSummary,
      let noInlineCodeSummary = inlineCodeRemover.visit(briefSummary) as? Paragraph
    else { return }

    // For the purposes of checking the sentence structure of the comment, we can operate on the
    // plain text; we don't need any of the styling.
    let trimmedText = noInlineCodeSummary.plainText
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let (commentSentences, trailingText) = sentences(in: trimmedText)
    if commentSentences.count == 0 {
      diagnose(.terminateSentenceWithPeriod(trimmedText), on: decl)
    } else if commentSentences.count > 1 {
      diagnose(.addBlankLineAfterFirstSentence(commentSentences[0]), on: decl)
      if !trailingText.isEmpty {
        diagnose(.terminateSentenceWithPeriod(trailingText), on: decl)
      }
    }
  }

  /// Returns all the sentences in the given text.
  ///
  /// This function uses linguistic APIs if they are available on the current platform; otherwise,
  /// simpler (and less accurate) character-based string APIs are substituted.
  ///
  /// - Parameter text: The text from which sentences should be extracted.
  /// - Returns: A tuple of two values: `sentences`, the array of sentences that were found, and
  ///   `trailingText`, which is any non-whitespace text after the last sentence that was not
  ///   terminated by sentence terminating punctuation. Note that if the entire string is a sequence
  ///   of words that contains _no_ terminating punctuation, the returned array will be empty to
  ///   indicate that there were no _complete_ sentences found, and `trailingText` will contain the
  ///   actual text).
  private func sentences(in text: String) -> (sentences: [String], trailingText: Substring) {
    #if os(macOS)
    if BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting {
      return nonLinguisticSentenceApproximations(in: text)
    }

    var sentences = [String]()
    var tags = [NLTag]()
    var tokenRanges = [Range<String.Index>]()

    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = text
    tagger.enumerateTags(
      in: text.startIndex..<text.endIndex,
      unit: .word,
      scheme: .lexicalClass
    ) { tag, range in
      if let tag {
        tags.append(tag)
        tokenRanges.append(range)
      }
      return true
    }

    var isInsideQuotes = false
    let sentenceTerminatorIndices = tags.enumerated().filter {
      if $0.element == NLTag.openQuote {
        isInsideQuotes = true
      } else if $0.element == NLTag.closeQuote {
        isInsideQuotes = false
      }
      return !isInsideQuotes && $0.element == NLTag.sentenceTerminator
    }.map {
      tokenRanges[$0.offset].lowerBound
    }

    var previous = text.startIndex
    for index in sentenceTerminatorIndices {
      let sentenceRange = previous...index
      sentences.append(text[sentenceRange].trimmingCharacters(in: .whitespaces))
      previous = text.index(after: index)
    }

    return (sentences: sentences, trailingText: text[previous..<text.endIndex])
    #else
    return nonLinguisticSentenceApproximations(in: text)
    #endif
  }

  /// The characters that the fallback implementation treats as full stops.
  ///
  /// Besides the ASCII period, this contains the ideographic full stop and its fullwidth and
  /// halfwidth forms, which are the ordinary full stops in CJK text. The linguistic APIs on Apple
  /// platforms already report all of these as sentence terminators, so recognizing them here keeps
  /// the two implementations in agreement.
  private static let fullStops: Set<Character> = [
    "\u{002E}",  // FULL STOP
    "\u{3002}",  // IDEOGRAPHIC FULL STOP
    "\u{FF0E}",  // FULLWIDTH FULL STOP
    "\u{FF61}",  // HALFWIDTH IDEOGRAPHIC FULL STOP
  ]

  /// Returns the best approximation of sentences in the given text using string splitting around
  /// full stops.
  ///
  /// This method is a fallback for platforms (like Linux, currently) that does not
  /// support `NaturalLanguage` and its related APIs. It will fail to catch certain kinds of
  /// sentences (such as those containing abbreviations that are followed by a period, like "Dr.")
  /// that the more advanced API can handle.
  private func nonLinguisticSentenceApproximations(
    in text: String
  ) -> (
    sentences: [String], trailingText: Substring
  ) {
    var sentences = [String]()
    var sentenceStart = text.startIndex
    var index = text.startIndex

    while index < text.endIndex {
      let next = text.index(after: index)
      defer { index = next }

      guard Self.fullStops.contains(text[index]) else { continue }

      // An ASCII period only ends a sentence when it is followed by a space or by the end of the
      // text, so that decimal points and abbreviations stay inside the sentence they belong to.
      // The CJK full stops are not written with a following space, so they always end a sentence.
      if text[index] == "." && next != text.endIndex && text[next] != " " {
        continue
      }

      sentences.append(String(text[sentenceStart..<next]).trimmingCharacters(in: .whitespaces))
      sentenceStart = next
    }

    // Anything after the last full stop was not terminated, so it is trailing text.
    let trailingText = text[sentenceStart...].drop { $0 == " " }
    return (sentences: sentences, trailingText: trailingText)
  }
}

extension Finding.Message {
  fileprivate static func terminateSentenceWithPeriod<Sentence: StringProtocol>(
    _ text: Sentence
  ) -> Finding.Message {
    "terminate this sentence with a period: \"\(text)\""
  }

  fileprivate static func addBlankLineAfterFirstSentence<Sentence: StringProtocol>(
    _ text: Sentence
  ) -> Finding.Message {
    "add a blank comment line after this sentence: \"\(text)\""
  }
}

struct InlineCodeRemover: MarkupRewriter {
  mutating func visitInlineCode(_ inlineCode: InlineCode) -> Markup? {
    nil
  }
}
