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
import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatPrettyPrint
import SwiftSyntax

/// Formats Swift source code or syntax trees according to the Swift style guidelines.
public final class SwiftFormatter {

  /// The configuration settings that control the formatter's behavior.
  public let configuration: Configuration

  /// A diagnostic engine to which non-fatal errors will be reported.
  public let diagnosticEngine: DiagnosticEngine?

  /// Advanced options that are useful when debugging the formatter's behavior but are not meant for
  /// general use.
  public var debugOptions: DebugOptions = []

  /// Creates a new Swift code formatter with the given configuration.
  ///
  /// - Parameters:
  ///   - configuration: The configuration settings that control the formatter's behavior.
  ///   - diagnosticEngine: The diagnostic engine to which non-fatal errors will be reported.
  ///     Defaults to nil.
  public init(configuration: Configuration, diagnosticEngine: DiagnosticEngine? = nil) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
  }

  /// Formats the Swift code at the given file URL and writes the result to an output stream.
  ///
  /// - Parameters:
  ///   - url: The URL of the file containing the code to format.
  ///   - outputStream: A value conforming to `TextOutputStream` to which the formatted output will
  ///     be written.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func format<Output: TextOutputStream>(
    contentsOf url: URL, to outputStream: inout Output
  ) throws {
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      throw SwiftFormatError.fileNotReadable
    }
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
      throw SwiftFormatError.isDirectory
    }
    let sourceFile = try SyntaxParser.parse(url)
    try format(syntax: sourceFile, assumingFileURL: url, to: &outputStream)
  }

  /// Formats the given Swift source code and writes the result to an output stream.
  ///
  /// - Parameters:
  ///   - source: The Swift source code to be formatted.
  ///   - url: A file URL denoting the filename/path that should be assumed for this syntax tree,
  ///     which is associated with any diagnostics emitted during formatting. If this is nil, a
  ///     dummy value will be used.
  ///   - outputStream: A value conforming to `TextOutputStream` to which the formatted output will
  ///     be written.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func format<Output: TextOutputStream>(
    source: String, assumingFileURL url: URL?, to outputStream: inout Output
  ) throws {
    let sourceFile = try SyntaxParser.parse(source: source)
    try format(syntax: sourceFile, assumingFileURL: url, to: &outputStream)
  }

  /// Formats the given Swift syntax tree and writes the result to an output stream.
  ///
  /// - Parameters:
  ///   - syntax: The Swift syntax tree to be converted to source code and formatted.
  ///   - url: A file URL denoting the filename/path that should be assumed for this syntax tree,
  ///     which is associated with any diagnostics emitted during formatting. If this is nil, a
  ///     dummy value will be used.
  ///   - outputStream: A value conforming to `TextOutputStream` to which the formatted output will
  ///     be written.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func format<Output: TextOutputStream>(
    syntax: SourceFileSyntax, assumingFileURL url: URL?, to outputStream: inout Output
  ) throws {
    if let position = firstInvalidSyntaxPosition(in: Syntax(syntax)) {
      throw SwiftFormatError.fileContainsInvalidSyntax(position: position)
    }

    let assumedURL = url ?? URL(fileURLWithPath: "source")
    let context = Context(
      configuration: configuration, diagnosticEngine: diagnosticEngine, fileURL: assumedURL,
      sourceFileSyntax: syntax)
    let pipeline = FormatPipeline(context: context)
    let transformedSyntax = pipeline.visit(Syntax(syntax))

    if debugOptions.contains(.disablePrettyPrint) {
      outputStream.write(transformedSyntax.description)
      return
    }

    let operatorContext = OperatorContext.makeBuiltinOperatorContext()
    let printer = PrettyPrinter(
      context: context,
      operatorContext: operatorContext,
      node: transformedSyntax,
      printTokenStream: debugOptions.contains(.dumpTokenStream),
      whitespaceOnly: configuration.whitespaceOnly)
    outputStream.write(printer.prettyPrint())
  }
}
