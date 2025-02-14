//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

extension Configuration {
  /// Return the configuration as a JSON string.
  public func asJsonString() throws -> String {
    let data: Data

    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      data = try encoder.encode(self)
    } catch {
      throw SwiftFormatError.configurationDumpFailed("\(error)")
    }

    guard let jsonString = String(data: data, encoding: .utf8) else {
      // This should never happen, but let's make sure we fail more gracefully than crashing, just in case.
      throw SwiftFormatError.configurationDumpFailed("The JSON was not valid UTF-8")
    }

    return jsonString
  }
}
