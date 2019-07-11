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
import SwiftFormatCore
import SwiftSyntax

/// Imports must be lexicographically ordered and logically grouped at the top of each source file.
/// The order of the import groups is 1) regular imports, 2) declaration imports, and 3) @testable
/// imports. These groups are separated by a single blank line. Blank lines in between the import
/// declarations are removed.
///
/// Lint: If an import appears anywhere other than the beginning of the file it resides in,
///       not lexicographically ordered, or  not in the appropriate import group, a lint error is
///       raised.
///
/// Format: Imports will be reordered and grouped at the top of the file.
///
/// - SeeAlso: https://google.github.io/swift#import-statements
public final class OrderedImports: SyntaxFormatRule {

  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    let lines = generateLines(codeBlockItemList: node.statements)

    var regularImports: [Line] = []
    var declImports: [Line] = []
    var testableImports: [Line] = []
    var codeBlocks: [Line] = []
    var fileHeader: [Line] = []

    var atStartOfFile = true
    var commentBuffer: [Line] = []

    for line in lines {

      // Capture any leading comments as the file header. It is assumed to be separated from the
      // rest of the file by a blank line.
      if atStartOfFile {
        switch line.type {
        case .comment:
          commentBuffer.append(line)
          continue

        case .blankLine:
          fileHeader.append(contentsOf: commentBuffer)
          fileHeader.append(line)
          commentBuffer = []
          continue

        default:
          atStartOfFile = false
        }
      }

      var lineType = line.type

      // Set the line type to codeBlock if the rule is disabled.
      if let codeblock = line.codeBlock, context.isRuleDisabled(self.ruleName, node: codeblock) {
        switch lineType {
        case .comment: ()
        default:
          lineType = .codeBlock
        }
      }

      // Separate lines into different categories along with any associated comments.
      switch lineType {
      case .regularImport:
        regularImports.append(contentsOf: commentBuffer)
        regularImports.append(line)
        commentBuffer = []

      case .testableImport:
        testableImports.append(contentsOf: commentBuffer)
        testableImports.append(line)
        commentBuffer = []

      case .declImport:
        declImports.append(contentsOf: commentBuffer)
        declImports.append(line)
        commentBuffer = []

      case .codeBlock, .blankLine:
        codeBlocks.append(contentsOf: commentBuffer)
        codeBlocks.append(line)
        commentBuffer = []

      case .comment:
        commentBuffer.append(line)
      }
    }
    codeBlocks.append(contentsOf: commentBuffer)

    // Perform linting on the grouping of the imports.
    checkGrouping(lines)

    if let lastLine = fileHeader.last, lastLine.type == .blankLine {
      fileHeader.removeLast()
    }

    regularImports = formatImports(regularImports)
    declImports = formatImports(declImports)
    testableImports = formatImports(testableImports)
    formatCodeblocks(&codeBlocks)

    let joined = joinLines(fileHeader, regularImports, declImports, testableImports, codeBlocks)

    return node.withStatements(
      SyntaxFactory.makeCodeBlockItemList(convertToCodeBlockItems(lines: joined))
    )
  }

  /// Raise lint errors if the different import types appear in the wrong order, and if import
  /// statements do not appear at the top of the file.
  private func checkGrouping(_ lines: [Line]) {
    var declGroup = false
    var testableGroup = false
    var codeGroup = false

    for line in lines {
      var lineType = line.type

      // Set the line type to codeBlock if the rule is disabled.
      if let codeblock = line.codeBlock, context.isRuleDisabled(self.ruleName, node: codeblock) {
        switch lineType {
        case .comment: ()
        default:
          lineType = .codeBlock
        }
      }

      switch lineType {
      case .declImport:
        declGroup = true
      case .testableImport:
        testableGroup = true
      case .codeBlock:
        codeGroup = true
      default: ()
      }

      if codeGroup {
        switch lineType {
        case .regularImport, .declImport, .testableImport:
          diagnose(.placeAtTopOfFile, on: line.codeBlock?.firstToken)
        default: ()
        }
      }

      if testableGroup {
        switch lineType {
        case .regularImport, .declImport:
          diagnose(
            .groupImports(before: lineType, after: LineType.testableImport),
            on: line.codeBlock?.firstToken
          )
        default: ()
        }
      }

      if declGroup {
        switch lineType {
        case .regularImport:
          diagnose(
            .groupImports(before: lineType, after: LineType.declImport),
            on: line.codeBlock?.firstToken
          )
        default: ()
        }
      }
    }
  }

  /// Sort the list of import lines lexicographically by the import path name. Any comments above an
  /// import lines should be assocaited with it, and move with the line during sorting. We also emit
  /// a linter error if an import line is discovered to be out of order.
  private func formatImports(_ imports: [Line]) -> [Line] {
    var linesWithLeadingComments: [(Line, [Line])] = []
    var commentBuffer: [Line] = []
    var previousImport: Line? = nil
    var diagnosed = false

    for line in imports {
      switch line.type {
      case .regularImport, .declImport, .testableImport:
        if let previousImport = previousImport,
          line.importName.lexicographicallyPrecedes(previousImport.importName) && !diagnosed
        {
          diagnose(.sortImports, on: line.codeBlock?.firstToken)
          diagnosed = true  // Only emit one of these errors to avoid alert fatigue.
        }
        // Pack the import line and its associated comments into a tuple.
        linesWithLeadingComments.append((line, commentBuffer))
        commentBuffer = []
        previousImport = line
      case .comment:
        commentBuffer.append(line)
      default: ()
      }
    }

    linesWithLeadingComments.sort { $0.0.importName.lexicographicallyPrecedes($1.0.importName) }

    // Unpack the tuples back into a list of Lines.
    var output: [Line] = []
    for lineTuple in linesWithLeadingComments {
      for comment in lineTuple.1 {
        output.append(comment)
      }
      output.append(lineTuple.0)
    }
    return output
  }
}

/// Remove any leading blank lines from the main code.
func formatCodeblocks(_ codeblocks: inout [Line]) {
  if let contentIndex = codeblocks.firstIndex(where: { !$0.isBlankLine }) {
    codeblocks.removeSubrange(0..<contentIndex)
  }
}

/// Join the lists of Line objects into a single list of Lines with a blank line separating them.
func joinLines(_ inputLineLists: [Line]...) -> [Line] {
  var lineLists = inputLineLists
  lineLists.removeAll { $0.isEmpty }
  var output: [Line] = lineLists.first ?? []
  for i in 1..<lineLists.count {
    let list = lineLists[i]
    if list.isEmpty { continue }
    output.append(Line())
    output += list
  }
  return output
}

/// This function transforms the statements in a CodeBlockItemListSyntax object into a list of Line
/// obejcts. Blank lines and standalone comments are represented by their own Line object. Code with
/// a trailing comment are represented together in the same Line.
func generateLines(codeBlockItemList: CodeBlockItemListSyntax) -> [Line] {
  var lines: [Line] = []
  var currentLine = Line()
  var afterNewline = false
  var isFirstBlock = true

  func appendNewLine() {
    lines.append(currentLine)
    currentLine = Line()
    afterNewline = true  // Note: trailing line comments always come before any newlines.
  }

  for block in codeBlockItemList {

    if let leadingTrivia = block.leadingTrivia {
      afterNewline = false

      for piece in leadingTrivia {
        switch piece {
        // Create new Line objects when we encounter newlines.
        case .newlines(let N):
          for _ in 0..<N {
            appendNewLine()
          }
        default:
          if afterNewline || isFirstBlock {
            currentLine.leadingTrivia.append(piece)  // This will be a standalone comment.
          } else {
            currentLine.trailingTrivia.append(piece)  // This will be a trailing line comment.
          }
        }
      }
    } else if currentLine.codeBlock != nil {
      appendNewLine()
    }
    currentLine.codeBlock = block  // This represents actual code: imports and otherwise.
    isFirstBlock = false
  }
  lines.append(currentLine)

  return lines
}

/// This function transforms a list of Line objects into a list of CodeBlockItemSyntax objects,
/// replacing the trivia appropriately to ensure comments appear in the right location.
func convertToCodeBlockItems(lines: [Line]) -> [CodeBlockItemSyntax] {
  var output: [CodeBlockItemSyntax] = []
  var triviaBuffer: [TriviaPiece] = []

  for line in lines {
    triviaBuffer += line.leadingTrivia
    if let block = line.codeBlock {
      // Comments and newlines are always located in the leading trivia of an AST node, so we need
      // not deal with trailing trivia.
      output.append(
        replaceTrivia(
          on: block,
          token: block.firstToken,
          leadingTrivia: Trivia(pieces: triviaBuffer)
        ) as! CodeBlockItemSyntax
      )
      triviaBuffer = []
      triviaBuffer += line.trailingTrivia
    }

    // Merge multiple newlines together into a single trivia piece by updating it's N value.
    if let lastPiece = triviaBuffer.last, case .newlines(let N) = lastPiece {
      triviaBuffer[triviaBuffer.endIndex - 1] = TriviaPiece.newlines(N + 1)
    } else {
      triviaBuffer.append(TriviaPiece.newlines(1))
    }
  }

  return output
}

enum LineType: CustomStringConvertible {
  case regularImport
  case declImport
  case testableImport
  case codeBlock
  case comment
  case blankLine

  var description: String {
    switch self {
    case .regularImport:
      return "regular"
    case .declImport:
      return "declaration"
    case .testableImport:
      return "testable"
    case .codeBlock:
      return "code"
    case .comment:
      return "comment"
    case .blankLine:
      return "blank line"
    }
  }
}

/// A Line more or less represents a literal printed line in a source file. A line can be a
/// comment, code, code with a trailing comment, or a blank line. For import statements, a Line will
/// represent a single printed line. Other types of code (e.g. structs and classes) will span
/// multiple literal lines, but can still be represented by a single Line object. This is desireable
/// since we aren't interested in rearranging those types of structures in this rule.
class Line {

  /// This is used to hold line comments. `codeBlock` need not be defined, since a comment can exist
  /// by itself on a line.
  var leadingTrivia: [TriviaPiece] = []

  /// These hold trailing line comments that follow normal code. `codeBlock` should be defined.
  var trailingTrivia: [TriviaPiece] = []

  /// This holds the actual CodeBlockItemSyntax object from the AST.
  var codeBlock: CodeBlockItemSyntax?

  /// A Line object can represent a blank line if all of its fields are empty.
  var isBlankLine: Bool {
    return leadingTrivia.isEmpty && trailingTrivia.isEmpty && codeBlock == nil
  }

  var type: LineType {
    if let block = codeBlock {
      if let importdecl = block.item as? ImportDeclSyntax {
        if let attr = importdecl.attributes?.firstToken,
          attr.tokenKind == .atSign,
          attr.nextToken?.text == "testable"
        {
          return LineType.testableImport
        }
        if importdecl.importKind != nil {
          return LineType.declImport
        }
        return LineType.regularImport
      } else {
        return LineType.codeBlock
      }
    } else if !leadingTrivia.isEmpty {
      return LineType.comment
    } else {
      return LineType.blankLine
    }
  }

  var importName: String {
    let importTypes: [LineType] = [.regularImport, .declImport, .testableImport]
    guard importTypes.contains(type), let block = codeBlock else { return "" }
    return (block.item as? ImportDeclSyntax)?.path.description ?? ""
  }
}

extension Diagnostic.Message {
  static let placeAtTopOfFile = Diagnostic.Message(
    .warning, "Place imports at the top of the file.")

  static func groupImports(before: LineType, after: LineType) -> Diagnostic.Message {
    return Diagnostic.Message(.warning, "Place \(before) imports before \(after) imports.")
  }

  static let sortImports = Diagnostic.Message(.warning, "Sort import statements lexicographically.")
}
