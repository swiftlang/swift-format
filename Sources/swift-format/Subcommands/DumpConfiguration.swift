//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Foundation
import SwiftFormat

extension SwiftFormatCommand {
  /// Dumps the tool's default configuration in JSON format to standard output.
  struct DumpConfiguration: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Dump the default configuration in JSON format to standard output"
    )

    func run() throws {
      let configuration = Configuration()
      do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if #available(macOS 10.13, *) {
          encoder.outputFormatting.insert(.sortedKeys)
        }

        let data = try encoder.encode(configuration)
        guard let jsonString = String(data: data, encoding: .utf8) else {
          // This should never happen, but let's make sure we fail more gracefully than crashing, just
          // in case.
          throw FormatError(
            message: "Could not dump the default configuration: the JSON was not valid UTF-8"
          )
        }
        print(jsonString)
      } catch {
        throw FormatError(message: "Could not dump the default configuration: \(error)")
      }
    }
  }
}
