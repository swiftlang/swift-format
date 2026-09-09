//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if !os(Windows)

import Foundation
@_spi(Internal) import SwiftFormat
import Testing

@Suite
struct DataWriteAtomicallyPreservingPermissionsTests {

  @Test(arguments: [0o600, 0o444, 0o755])
  func keepsThePermissionsTheFileHad(mode: Int) throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("SwiftFormatPermissionsTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let file = directory.appendingPathComponent("Test.swift")
    try "class Test {}".write(to: file, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: file.path)

    try Data("class Formatted {}".utf8).writeAtomicallyPreservingPermissions(to: file)

    let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
    #expect(attributes[.posixPermissions] as? Int == mode)
    #expect(try String(contentsOf: file, encoding: .utf8) == "class Formatted {}")
  }

  @Test func writesAFileThatDidNotExist() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("SwiftFormatPermissionsTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let file = directory.appendingPathComponent("New.swift")
    try Data("class New {}".utf8).writeAtomicallyPreservingPermissions(to: file)

    #expect(try String(contentsOf: file, encoding: .utf8) == "class New {}")
  }
}

#endif
