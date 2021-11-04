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

import Dispatch
import Foundation
import TSCBasic

/// The queue used to synchronize printing uninterrupted diagnostic messages.
private let printQueue = DispatchQueue(label: "com.apple.swift-format.printDiagnosticToStderr")

/// Prints a diagnostic to standard error.
func printDiagnosticToStderr(_ diagnostic: TSCBasic.Diagnostic) {
  printQueue.sync {
    let stderr = FileHandle.standardError

    stderr.write("\(diagnostic.location): ")

    switch diagnostic.behavior {
    case .error: stderr.write("error: ")
    case .warning: stderr.write("warning: ")
    case .note: stderr.write("note: ")
    case .remark, .ignored: break
    }

    stderr.write(diagnostic.message.text)
    stderr.write("\n")
  }
}
