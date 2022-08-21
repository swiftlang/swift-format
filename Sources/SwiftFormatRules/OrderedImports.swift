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
public final class OrderedImports: SyntaxFormatRule {

  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    let lines = generateLines(codeBlockItemList: node.statements, context: context)

    // Stores the formatted and sorted lines that will be used to reconstruct the list of code block
    // items later.
    var formattedLines: [Line] = []

    var regularImports: [Line] = []
    var declImports: [Line] = []
    var testableImports: [Line] = []
    var codeBlocks: [Line] = []
    var fileHeader: [Line] = []
    var atStartOfFile = true
    var commentBuffer: [Line] = []

    func formatAndAppend(linesSection: ArraySlice<Line>) {
      codeBlocks.append(contentsOf: commentBuffer)

      // Perform linting on the grouping of the imports.
      checkGrouping(linesSection)

      if let lastLine = fileHeader.last, lastLine.type == .blankLine {
        fileHeader.removeLast()
      }

      regularImports = formatImports(regularImports)
      declImports = formatImports(declImports)
      testableImports = formatImports(testableImports)
      formatCodeblocks(&codeBlocks)

      let joined = joinLines(fileHeader, regularImports, declImports, testableImports, codeBlocks)
      formattedLines.append(contentsOf: joined)

      regularImports = []
      declImports = []
      testableImports = []
      codeBlocks = []
      fileHeader = []
      commentBuffer = []
    }

    var lastSliceStartIndex = 0
    for (index, line) in lines.enumerated() {

      if let syntaxNode = line.syntaxNode,
        case .importCodeBlock(_, let sortable) = syntaxNode, !sortable
      {
        formatAndAppend(linesSection: lines[lastSliceStartIndex..<index])
        formattedLines.append(line)
        // Insert a blank line after the unsorted import to show that it's a separate "group" from
        // the sorted imports.
        formattedLines.append(Line())
        lastSliceStartIndex = index + 1  // Add 1 to skip the current line.
        continue
      }

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

      // Separate lines into different categories along with any associated comments.
      switch line.type {
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

    if lastSliceStartIndex < lines.endIndex {
      formatAndAppend(linesSection: lines[lastSliceStartIndex..<lines.endIndex])
    }

    let newNode = node.withStatements(
      CodeBlockItemListSyntax(convertToCodeBlockItems(lines: formattedLines))
    )
    return Syntax(newNode)
  }

  /// Raise lint errors if the different import types appear in the wrong order, and if import
  /// statements do not appear at the top of the file.
  private func checkGrouping<C: Collection>(_ lines: C) where C.Element == Line {
    var declGroup = false
    var testableGroup = false
    var codeGroup = false

    for line in lines {
      let lineType = line.type

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
          diagnose(.placeAtTopOfFile, on: line.firstToken)
        default: ()
        }
      }

      if testableGroup {
        switch lineType {
        case .regularImport, .declImport:
          diagnose(
            .groupImports(before: lineType, after: LineType.testableImport), on: line.firstToken
          )
        default: ()
        }
      }

      if declGroup {
        switch lineType {
        case .regularImport:
          diagnose(
            .groupImports(before: lineType, after: LineType.declImport), on: line.firstToken
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
    var linesWithLeadingComments: [(import: Line, comments: [Line])] = []
    var visitedImports: [String: Int] = [:]
    var commentBuffer: [Line] = []
    var previousImport: Line? = nil
    var diagnosed = false

    for line in imports {
      switch line.type {
      case .regularImport, .declImport, .testableImport:
        let fullyQualifiedImport = line.fullyQualifiedImport
        // Check for duplicate imports and potentially remove them.
        if let previousMatchingImportIndex = visitedImports[fullyQualifiedImport] {
          // Even if automatically removing this import is impossible, alert the user that this is a
          // duplicate so they can manually fix it.
          diagnose(.removeDuplicateImport, on: line.firstToken)
          var duplicateLine = linesWithLeadingComments[previousMatchingImportIndex]

          // We can combine multiple leading comments, but it's unsafe to combine trailing comments.
          // Any extra comments must go on a new line, and would be grouped with the next import.
          guard !duplicateLine.import.trailingTrivia.isEmpty && !line.trailingTrivia.isEmpty else {
            duplicateLine.comments.append(contentsOf: commentBuffer)
            commentBuffer = []
            // Keep the Line that has the trailing comment, if there is one.
            if !line.trailingTrivia.isEmpty {
              duplicateLine.import = line
            }
            linesWithLeadingComments[previousMatchingImportIndex] = duplicateLine
            continue
          }
          // Otherwise, both lines have trailing trivia so it's not safe to automatically merge
          // them. Leave this duplicate import.
        }
        if let previousImport = previousImport,
          line.importName.lexicographicallyPrecedes(previousImport.importName) && !diagnosed
            // Only warn to sort imports that shouldn't be removed.
            && visitedImports[fullyQualifiedImport] == nil
        {
          diagnose(.sortImports, on: line.firstToken)
          diagnosed = true  // Only emit one of these errors to avoid alert fatigue.
        }

        // Pack the import line and its associated comments into a tuple.
        linesWithLeadingComments.append((line, commentBuffer))
        commentBuffer = []
        previousImport = line
        visitedImports[fullyQualifiedImport] = linesWithLeadingComments.endIndex - 1
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
fileprivate func formatCodeblocks(_ codeblocks: inout [Line]) {
  if let contentIndex = codeblocks.firstIndex(where: { !$0.isBlankLine }) {
    codeblocks.removeSubrange(0..<contentIndex)
  }
}

/// Join the lists of Line objects into a single list of Lines with a blank line separating them.
fileprivate func joinLines(_ inputLineLists: [Line]...) -> [Line] {
  var lineLists = inputLineLists
  lineLists.removeAll { $0.isEmpty }
  guard lineLists.count > 0 else { return [] }
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
fileprivate func generateLines(codeBlockItemList: CodeBlockItemListSyntax, context: Context)
  -> [Line]
{
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
    }

    if block.item.is(ImportDeclSyntax.self) {
      // Always create a new `Line` for each import statement, so they can be reordered.
      if currentLine.syntaxNode != nil {
        lines.append(currentLine)
        currentLine = Line()
      }
      let sortable = context.isRuleEnabled(OrderedImports.self, node: Syntax(block))
      currentLine.syntaxNode = .importCodeBlock(block, sortable: sortable)
    } else {
      guard let syntaxNode = currentLine.syntaxNode else {
        currentLine.syntaxNode = .nonImportCodeBlocks([block])
        continue
      }
      // Multiple code blocks can be merged, as long as there isn't an import statement.
      switch syntaxNode {
      case .importCodeBlock:
        lines.append(currentLine)
        currentLine = Line()
        currentLine.syntaxNode = .nonImportCodeBlocks([block])
      case .nonImportCodeBlocks(let existingCodeBlocks):
        currentLine.syntaxNode = .nonImportCodeBlocks(existingCodeBlocks + [block])
      }
    }

    isFirstBlock = false
  }
  lines.append(currentLine)

  return lines
}

/// This function transforms a list of Line objects into a list of CodeBlockItemSyntax objects,
/// replacing the trivia appropriately to ensure comments appear in the right location.
fileprivate func convertToCodeBlockItems(lines: [Line]) -> [CodeBlockItemSyntax] {
  var output: [CodeBlockItemSyntax] = []
  var triviaBuffer: [TriviaPiece] = []

  for line in lines {
    triviaBuffer += line.leadingTrivia

    func append(codeBlockItem: CodeBlockItemSyntax) {
      // Comments and newlines are always located in the leading trivia of an AST node, so we need
      // not deal with trailing trivia.
      output.append(
        replaceTrivia(
          on: codeBlockItem,
          token: codeBlockItem.firstToken,
          leadingTrivia: Trivia(pieces: triviaBuffer)
        )
      )
      triviaBuffer = []
      triviaBuffer += line.trailingTrivia
    }

    if let syntaxNode = line.syntaxNode {
      switch syntaxNode {
      case .importCodeBlock(let codeBlock, _):
        append(codeBlockItem: codeBlock)
      case .nonImportCodeBlocks(let codeBlocks):
        codeBlocks.forEach(append(codeBlockItem:))
      }
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

public enum LineType: CustomStringConvertible {
  case regularImport
  case declImport
  case testableImport
  case codeBlock
  case comment
  case blankLine

  public var description: String {
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
fileprivate class Line {
  /// Storage for the different types of AST nodes that can be held by a `Line`.
  enum SyntaxNode {
    /// A collection of code block items that aren't imports. These types of code blocks aren't
    /// reordered and there may be multiple per printed line.
    case nonImportCodeBlocks([CodeBlockItemSyntax])
    /// A single code block item whose content must be an import decl.
    case importCodeBlock(CodeBlockItemSyntax, sortable: Bool)
  }

  /// Stores line comments. `syntaxNode` need not be defined, since a comment can exist by itself on
  /// a line.
  var leadingTrivia: [TriviaPiece] = []

  /// Stores trailing line comments that follow normal code. `syntaxNode` should be defined.
  var trailingTrivia: [TriviaPiece] = []

  /// Stores one or more CodeBlockItemSyntax objects from the AST.
  var syntaxNode: SyntaxNode?

  /// A Line object can represent a blank line if all of its fields are empty.
  var isBlankLine: Bool {
    return leadingTrivia.isEmpty && trailingTrivia.isEmpty && syntaxNode == nil
  }

  var type: LineType {
    if let syntaxNode = syntaxNode {
      switch syntaxNode {
      case .nonImportCodeBlocks:
        return .codeBlock
      case .importCodeBlock(let importCodeBlock, _):
        guard let importDecl = importCodeBlock.item.as(ImportDeclSyntax.self) else {
          // Invalid `importCodeBlock` - fallback to treating it as a generic code block.
          return .codeBlock
        }
        return importType(of: importDecl)
      }
    }

    if leadingTrivia.contains(where: {
      switch $0 {
      case .lineComment, .blockComment, .docLineComment, .docBlockComment:
        return true
      default:
        return false
      }
    }) {
      return .comment
    }

    // There may be some whitespace in the leading trivia, but consider the line to be blank.
    return .blankLine
  }

  /// Returns a fully qualified description of this line's import if it's an import statement,
  /// including any attributes, modifiers, the import kind, and the import path. When this line
  /// isn't an import statement, returns an empty string.
  var fullyQualifiedImport: String {
    guard let syntaxNode = syntaxNode, case .importCodeBlock(let importCodeBlock, _) = syntaxNode,
      let importDecl = importCodeBlock.item.as(ImportDeclSyntax.self)
    else {
      return ""
    }
    // Using the description is a reliable way to include all content from the import, but
    // description includes all leading and trailing trivia. It would be unusual to have any
    // non-whitespace trivia on the components of the import. Trim off the leading trivia, where
    // comments could be, and trim whitespace that might be after the import.
    let leadingText = importDecl.leadingTrivia?.reduce(into: "") { $1.write(to: &$0) } ?? ""
    return importDecl.description.dropFirst(leadingText.count)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Returns the path that is imported by this line's import statement if it's an import statement.
  /// When this line isn't an import statement, returns an empty string.
  var importName: String {
    guard let syntaxNode = syntaxNode, case .importCodeBlock(let importCodeBlock, _) = syntaxNode,
      let importDecl = importCodeBlock.item.as(ImportDeclSyntax.self)
    else {
      return ""
    }
    return importDecl.path.description.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Returns the first `TokenSyntax` in the code block(s) from this Line, or nil when this Line
  /// doesn't represent any code blocks (e.g. a comment or blank line).
  var firstToken: TokenSyntax? {
    guard let syntaxNode = syntaxNode else { return nil }
    switch syntaxNode {
    case .importCodeBlock(let codeBlock, _):
      return codeBlock.firstToken
    case .nonImportCodeBlocks(let codeBlocks):
      return codeBlocks.first?.firstToken
    }
  }

  /// Returns a `LineType` the represents the type of import from the given import decl.
  private func importType(of importDecl: ImportDeclSyntax) -> LineType {
    if let attr = importDecl.attributes?.firstToken,
      attr.tokenKind == .atSign,
      attr.nextToken?.text == "testable"
    {
      return .testableImport
    }
    if importDecl.importKind != nil {
      return .declImport
    }
    return .regularImport
  }
}

extension Line: CustomDebugStringConvertible {
  var debugDescription: String {
    var description = ""
    if !leadingTrivia.isEmpty {
      var newlinesCount = 0
      for piece in leadingTrivia {
        switch piece {
        case .newlines(let count):
          newlinesCount += count
        default:
          if newlinesCount > 0 {
            description += "\(newlinesCount) newlines "
            newlinesCount = 0
          }
          description += "\(piece) "
        }
      }
      if newlinesCount > 0 {
        description += "\(newlinesCount) newlines "
      }
    }

    if let syntaxNode = syntaxNode {
      switch syntaxNode {
      case .nonImportCodeBlocks(let codeBlocks):
        description += "\(codeBlocks.count) code blocks "
      case .importCodeBlock(_, let sortable):
        description += "\(sortable ? "sorted" : "unsorted") import \(importName) "
      }
    }

    if !trailingTrivia.isEmpty {
      // Trailing trivia should just be comments, so just print each piece.
      for piece in trailingTrivia {
        description += "\(piece) "
      }
    }

    return description.trimmingCharacters(in: .whitespaces)
  }
}

extension Finding.Message {
  public static let placeAtTopOfFile: Finding.Message = "place imports at the top of the file"

  public static func groupImports(before: LineType, after: LineType) -> Finding.Message {
    "place \(before) imports before \(after) imports"
  }

  public static let removeDuplicateImport: Finding.Message = "remove duplicate import"

  public static let sortImports: Finding.Message = "sort import statements lexicographically"
}
