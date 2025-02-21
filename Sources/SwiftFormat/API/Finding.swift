//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A problem with the style or syntax of the source code discovered during linting or formatting.
public struct Finding {

  /// The file path and location in that file where a finding was encountered.
  public struct Location {
    /// The file path of the finding.
    public var file: String

    /// The 1-based line number of the finding.
    public var line: Int

    /// The 1-based column number of the finding.
    public var column: Int

    /// Creates a new finding with the given file path and 1-based line and column numbers.
    public init(file: String, line: Int, column: Int) {
      self.file = file
      self.line = line
      self.column = column
    }
  }

  /// A descriptive message about a finding.
  ///
  /// Finding messages are strongly typed so that they can act as an extensible namespace for
  /// messages defined by rules and other components of the formatter. To accomplish this, declare
  /// an `extension` of the `Finding.Message` type and add `static` properties or functions of type
  /// `Finding.Message`; these can be initialized using string literals or string interpolations.
  public struct Message:
    CustomStringConvertible, ExpressibleByStringLiteral, ExpressibleByStringInterpolation
  {
    /// The message text of the diagnostic.
    public var text: String

    public var description: String { text }

    public init(stringLiteral string: String) {
      self.text = string
    }

    public init(stringInterpolation: DefaultStringInterpolation) {
      self.text = String(describing: stringInterpolation)
    }
  }

  /// A note associating additional detail with a finding.
  public struct Note {
    /// The note's message.
    public var message: Message

    /// The optional location of the note, if different from the location of the finding.
    public var location: Location?

    /// Creates a new note with the given message and location.
    public init(message: Message, location: Location? = nil) {
      self.message = message
      self.location = location
    }
  }

  /// The category associated with the finding.
  public let category: FindingCategorizing

  /// The finding's message.
  public let message: Message

  /// The optional location of the finding.
  public let location: Location?

  /// Notes that provide additional detail about the finding.
  public let notes: [Note]

  /// Creates a new finding with the given category, message, optional location, and
  /// notes.
  init(
    category: FindingCategorizing,
    message: Message,
    location: Location? = nil,
    notes: [Note] = []
  ) {
    self.category = category
    self.message = message
    self.location = location
    self.notes = notes
  }
}
