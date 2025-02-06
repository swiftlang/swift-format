//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormat

/// The frontend for dumping the effective configuration.
class DumpEffectiveConfigurationFrontend: Frontend {
  private(set) var dumpResult: Result<String, Error> = .failure(
    SwiftFormatError.configurationDumpFailed("Configuration not resolved yet")
  )

  override func processFile(_ fileToProcess: FileToProcess) {
    dumpResult = Result.init(catching: fileToProcess.configuration.asJsonString)
  }
}
