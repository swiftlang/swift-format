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

/// Manages printing of diagnostics to standard error.
final class StderrDiagnosticPrinter {
  /// Determines how colors are used in printed diagnostics.
  enum ColorMode {
    /// Colors are used if stderr is detected to be connected to a TTY; otherwise, colors will not
    /// be used (for example, if stderr is redirected to a file).
    case auto

    /// Colors will not be used.
    case off

    /// Colors will always be used.
    case on
  }

  /// Definitions of the ANSI "Select Graphic Rendition" sequences used in diagnostics.
  private enum ANSISGR: String {
    case boldRed = "1;31"
    case boldYellow = "1;33"
    case boldMagenta = "1;35"
    case boldWhite = "1;37"
    case boldGray = "1;90"
    case reset = "0"
  }

  /// The queue used to synchronize printing uninterrupted diagnostic messages.
  private let printQueue = DispatchQueue(label: "com.apple.swift-format.StderrDiagnosticPrinter")

  /// Indicates whether colors should be used when printing diagnostics.
  private let useColors: Bool

  /// Creates a new standard error diagnostic printer with the given color mode.
  init(colorMode: ColorMode) {
    switch colorMode {
    case .auto:
      if let stream = stderrStream.stream as? LocalFileOutputByteStream {
        useColors = TerminalController.isTTY(stream)
      } else {
        useColors = false
      }
    case .off:
      useColors = false
    case .on:
      useColors = true
    }
  }

  /// Prints a diagnostic to standard error.
  func printDiagnostic(_ diagnostic: TSCBasic.Diagnostic) {
    printQueue.sync {
      let stderr = FileHandleTextOutputStream(FileHandle.standardError)

      stderr.write("\(ansiSGR(.boldWhite))\(diagnostic.location): ")

      switch diagnostic.behavior {
      case .error: stderr.write("\(ansiSGR(.boldRed))error: ")
      case .warning: stderr.write("\(ansiSGR(.boldMagenta))warning: ")
      case .note: stderr.write("\(ansiSGR(.boldGray))note: ")
      case .remark, .ignored: break
      }

      let data = diagnostic.data as! UnifiedDiagnosticData
      if let category = data.category {
        stderr.write("\(ansiSGR(.boldYellow))[\(category)] ")
      }
      stderr.write("\(ansiSGR(.boldWhite))\(data.message)\(ansiSGR(.reset))\n")
    }
  }

  /// Returns the complete ANSI sequence used to enable the given SGR if colors are enabled in the
  /// printer, or the empty string if colors are not enabled.
  private func ansiSGR(_ ansiSGR: ANSISGR) -> String {
    guard useColors else { return "" }
    return "\u{001b}[\(ansiSGR.rawValue)m"
  }
}
