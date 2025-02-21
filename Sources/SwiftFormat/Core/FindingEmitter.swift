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

/// Emits findings encountered during linting or formatting.
///
/// The finding emitter is initialized with an optional consumer function that will be invoked each
/// time a finding is emitted when linting or formatting the syntax tree. This function is expected
/// to act on the finding -- for example, by printing it as a diagnostic to standard error.
///
/// If the consumer function is nil, then the `emit` function is a no-op. This allows callers, such
/// as lint/format rules and the pretty-printer, to emit findings unconditionally, without wrapping
/// each call in a check about whether the client is interested in receiving those findings or not.
final class FindingEmitter {
  /// An optional function that will be called and passed a finding each time one is emitted.
  private let consumer: ((Finding) -> Void)?

  /// Creates a new finding emitter with the given consumer function.
  ///
  /// - Parameter consumer: An optional function that will be called and passed a finding each time
  ///   one is emitted.
  public init(consumer: ((Finding) -> Void)?) {
    self.consumer = consumer
  }

  /// Emits a new finding.
  ///
  /// - Parameters:
  ///   - message: A descriptive message about the finding.
  ///   - category: A value that groups the finding into a category.
  ///   - location: The source location where the finding was encountered. In rare cases where the
  ///     finding does not apply to a particular location in the source code, this may be nil.
  ///   - notes: Notes that provide additional detail about the finding, possibly referring to other
  ///     related locations in the source file.
  public func emit(
    _ message: Finding.Message,
    category: FindingCategorizing,
    location: Finding.Location? = nil,
    notes: [Finding.Note] = []
  ) {
    guard let consumer = self.consumer else { return }

    consumer(
      Finding(
        category: category,
        message: message,
        location: location,
        notes: notes
      )
    )
  }
}
