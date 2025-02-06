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

/// The frontend for dumping the configuration.
class DumpConfigurationFrontend: Frontend {
  private(set) var dumpedConfiguration: Result<String, Error> = .failure(
    SwiftFormatError.configurationDumpFailed("Configuration not dumped yet")
  )

  override func processFile(_ fileToProcess: FileToProcess) {
    dumpedConfiguration = Result.init(catching: fileToProcess.configuration.asJsonString)
  }
}
