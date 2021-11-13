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

/// A version number that can be specified in the configuration file, which allows us to change the
/// format in the future if desired and still support older files.
fileprivate let highestSupportedConfigurationVersion = 1

/// Holds the complete set of configured values and defaults.
public struct Configuration: Codable, Equatable {

  private enum CodingKeys: CodingKey {
    case version
    case maximumBlankLines
    case lineLength
    case tabWidth
    case indentation
    case respectsExistingLineBreaks
    case lineBreakBeforeControlFlowKeywords
    case lineBreakBeforeEachArgument
    case lineBreakBeforeEachGenericRequirement
    case prioritizeKeepingFunctionOutputTogether
    case indentConditionalCompilationBlocks
    case lineBreakAroundMultilineExpressionChainComponents
    case fileScopedDeclarationPrivacy
    case indentSwitchCaseLabels
    case rules
  }

  /// The version of this configuration.
  private let version: Int

  /// MARK: Common configuration

  /// The dictionary containing the rule names that we wish to run on. A rule is not used if it is
  /// marked as `false`, or if it is missing from the dictionary.
  public var rules: [String: Bool] = RuleRegistry.rules

  /// The maximum number of consecutive blank lines that may appear in a file.
  public var maximumBlankLines = 1

  /// The maximum length of a line of source code, after which the formatter will break lines.
  public var lineLength = 100

  /// The width of the horizontal tab in spaces.
  ///
  /// This value is used when converting indentation types (for example, from tabs into spaces).
  public var tabWidth = 8

  /// A value representing a single level of indentation.
  ///
  /// All indentation will be conducted in multiples of this configuration.
  public var indentation: Indent = .spaces(2)

  /// Indicates that the formatter should try to respect users' discretionary line breaks when
  /// possible.
  ///
  /// For example, a short `if` statement and its single-statement body might be able to fit on one
  /// line, but for readability the user might break it inside the curly braces. If this setting is
  /// true, those line breaks will be kept. If this setting is false, the formatter will act more
  /// "opinionated" and collapse the statement onto a single line.
  public var respectsExistingLineBreaks = true

  /// MARK: Rule-specific configuration

  /// Determines the line-breaking behavior for control flow keywords that follow a closing brace,
  /// like `else` and `catch`.
  ///
  /// If true, a line break will be added before the keyword, forcing it onto its own line. If
  /// false (the default), the keyword will be placed after the closing brace (separated by a
  /// space).
  public var lineBreakBeforeControlFlowKeywords = false

  /// Determines the line-breaking behavior for generic arguments and function arguments when a
  /// declaration is wrapped onto multiple lines.
  ///
  /// If false (the default), arguments will be laid out horizontally first, with line breaks only
  /// being fired when the line length would be exceeded. If true, a line break will be added before
  /// each argument, forcing the entire argument list to be laid out vertically.
  public var lineBreakBeforeEachArgument = false

  /// Determines the line-breaking behavior for generic requirements when the requirements list
  /// is wrapped onto multiple lines.
  ///
  /// If true, a line break will be added before each requirement, forcing the entire requirements
  /// list to be laid out vertically. If false (the default), requirements will be laid out
  /// horizontally first, with line breaks only being fired when the line length would be exceeded.
  public var lineBreakBeforeEachGenericRequirement = false

  /// Determines if function-like declaration outputs should be prioritized to be together with the
  /// function signature right (closing) parenthesis.
  ///
  /// If false (the default), function output (i.e. throws, return type) is not prioritized to be
  /// together with the signature's right parenthesis, and when the line length would be exceeded,
  /// a line break will be fired after the function signature first, indenting the declaration output
  /// one additional level. If true, A line break will be fired further up in the function's
  /// declaration (e.g. generic parameters, parameters) before breaking on the function's output.
  public var prioritizeKeepingFunctionOutputTogether = false

  /// Determines the indentation behavior for `#if`, `#elseif`, and `#else`.
  public var indentConditionalCompilationBlocks = true

  /// Determines whether line breaks should be forced before and after multiline components of
  /// dot-chained expressions, such as function calls and subscripts chained together through member
  /// access (i.e. "." expressions). When any component is multiline and this option is true, a line
  /// break is forced before the "." of the component and after the component's closing delimiter
  /// (i.e. right paren, right bracket, right brace, etc.).
  public var lineBreakAroundMultilineExpressionChainComponents = false

  /// Determines the formal access level (i.e., the level specified in source code) for file-scoped
  /// declarations whose effective access level is private to the containing file.
  public var fileScopedDeclarationPrivacy = FileScopedDeclarationPrivacyConfiguration()

  /// Determines if `case` statements should be indented compared to the containing `switch` block.
  ///
  /// When `false`, the correct form is:
  /// ```swift
  /// switch someValue {
  /// case someCase:
  ///   someStatement
  /// ...
  /// }
  /// ```
  ///
  /// When `true`, the correct form is:
  /// ```swift
  /// switch someValue {
  ///   case someCase:
  ///     someStatement
  ///   ...
  /// }
  ///```
  public var indentSwitchCaseLabels = false

  /// Constructs a Configuration with all default values.
  public init() {
    self.version = highestSupportedConfigurationVersion
  }

  /// Constructs a Configuration by loading it from a configuration file.
  public init(contentsOf url: URL) throws {
    let data = try Data(contentsOf: url)
    self = try JSONDecoder().decode(Configuration.self, from: data)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Unfortunately, to allow the user to leave out configuration options in the JSON, we would
    // have to make them optional properties, but that makes using the type in the rest of the code
    // more annoying because we'd have to unwrap everything. So, we override this initializer and
    // provide the defaults ourselves if needed.

    // If the version number is not present, assume it is 1.
    self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
    guard version <= highestSupportedConfigurationVersion else {
      throw DecodingError.dataCorruptedError(
        forKey: .version, in: container,
        debugDescription:
          "This version of the formatter does not support configuration version \(version).")
    }

    // If we ever introduce a new version, this is where we should switch on the decoded version
    // number and dispatch to different decoding methods.

    self.maximumBlankLines
      = try container.decodeIfPresent(Int.self, forKey: .maximumBlankLines) ?? 1
    self.lineLength = try container.decodeIfPresent(Int.self, forKey: .lineLength) ?? 100
    self.tabWidth = try container.decodeIfPresent(Int.self, forKey: .tabWidth) ?? 8
    self.indentation
      = try container.decodeIfPresent(Indent.self, forKey: .indentation) ?? .spaces(2)
    self.respectsExistingLineBreaks
      = try container.decodeIfPresent(Bool.self, forKey: .respectsExistingLineBreaks) ?? true
    self.lineBreakBeforeControlFlowKeywords
      = try container.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeControlFlowKeywords) ?? false
    self.lineBreakBeforeEachArgument
      = try container.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeEachArgument) ?? false
    self.lineBreakBeforeEachGenericRequirement
      = try container.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeEachGenericRequirement) ?? false
    self.prioritizeKeepingFunctionOutputTogether
      = try container.decodeIfPresent(Bool.self, forKey: .prioritizeKeepingFunctionOutputTogether) ?? false
    self.indentConditionalCompilationBlocks
      = try container.decodeIfPresent(Bool.self, forKey: .indentConditionalCompilationBlocks) ?? true
    self.lineBreakAroundMultilineExpressionChainComponents =
      try container.decodeIfPresent(
        Bool.self, forKey: .lineBreakAroundMultilineExpressionChainComponents) ?? false
    self.fileScopedDeclarationPrivacy =
      try container.decodeIfPresent(
        FileScopedDeclarationPrivacyConfiguration.self, forKey: .fileScopedDeclarationPrivacy)
      ?? FileScopedDeclarationPrivacyConfiguration()
    self.indentSwitchCaseLabels
      = try container.decodeIfPresent(Bool.self, forKey: .indentSwitchCaseLabels) ?? false

    // If the `rules` key is not present at all, default it to the built-in set
    // so that the behavior is the same as if the configuration had been
    // default-initialized. To get an empty rules dictionary, one can explicitly
    // set the `rules` key to `{}`.
    self.rules
      = try container.decodeIfPresent([String: Bool].self, forKey: .rules) ?? RuleRegistry.rules
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(version, forKey: .version)
    try container.encode(maximumBlankLines, forKey: .maximumBlankLines)
    try container.encode(lineLength, forKey: .lineLength)
    try container.encode(tabWidth, forKey: .tabWidth)
    try container.encode(indentation, forKey: .indentation)
    try container.encode(respectsExistingLineBreaks, forKey: .respectsExistingLineBreaks)
    try container.encode(lineBreakBeforeControlFlowKeywords, forKey: .lineBreakBeforeControlFlowKeywords)
    try container.encode(lineBreakBeforeEachArgument, forKey: .lineBreakBeforeEachArgument)
    try container.encode(lineBreakBeforeEachGenericRequirement, forKey: .lineBreakBeforeEachGenericRequirement)
    try container.encode(prioritizeKeepingFunctionOutputTogether, forKey: .prioritizeKeepingFunctionOutputTogether)
    try container.encode(indentConditionalCompilationBlocks, forKey: .indentConditionalCompilationBlocks)
    try container.encode(
      lineBreakAroundMultilineExpressionChainComponents,
      forKey: .lineBreakAroundMultilineExpressionChainComponents)
    try container.encode(fileScopedDeclarationPrivacy, forKey: .fileScopedDeclarationPrivacy)
    try container.encode(indentSwitchCaseLabels, forKey: .indentSwitchCaseLabels)
    try container.encode(rules, forKey: .rules)
  }

  /// Returns the URL of the configuration file that applies to the given file or directory.
  public static func url(forConfigurationFileApplyingTo url: URL) -> URL? {
    // Despite the variable's name, this value might start out first as a file path (the path to a
    // source file being formatted). However, it will immediately have its basename removed in the
    // loop below, and from then on serve as a directory path only.
    var candidateDirectory = url.absoluteURL.standardized
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: candidateDirectory.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    {
      // If the path actually was a directory, append a fake basename so that the trimming code
      // below doesn't have to deal with the first-time special case.
      candidateDirectory.appendPathComponent("placeholder")
    }
    repeat {
      candidateDirectory.deleteLastPathComponent()
      let candidateFile = candidateDirectory.appendingPathComponent(".swift-format")
      if FileManager.default.isReadableFile(atPath: candidateFile.path) {
        return candidateFile
      }
    } while candidateDirectory.path != "/"

    return nil
  }
}

/// Configuration for the `FileScopedDeclarationPrivacy` rule.
public struct FileScopedDeclarationPrivacyConfiguration: Codable, Equatable {
  public enum AccessLevel: String, Codable {
    /// Private file-scoped declarations should be declared `private`.
    ///
    /// If a file-scoped declaration is declared `fileprivate`, it will be diagnosed (in lint mode)
    /// or changed to `private` (in format mode).
    case `private`

    /// Private file-scoped declarations should be declared `fileprivate`.
    ///
    /// If a file-scoped declaration is declared `private`, it will be diagnosed (in lint mode) or
    /// changed to `fileprivate` (in format mode).
    case `fileprivate`
  }

  /// The formal access level to use when encountering a file-scoped declaration with effective
  /// private access.
  public var accessLevel: AccessLevel = .private
}
