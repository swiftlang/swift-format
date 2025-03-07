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

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoPlaygroundLiteralsTests: LintOrFormatRuleTestCase {
  func testColorLiterals() {
    assertLint(
      NoPlaygroundLiterals.self,
      """
      _ = 1️⃣#colorLiteral(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      _ = #otherMacro(color: 2️⃣#colorLiteral(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
      _ = #otherMacro { 3️⃣#colorLiteral(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) }

      // Ignore invalid expansions.
      _ = #colorLiteral(1.0, 0.0, 0.0, 1.0)
      _ = #colorLiteral(r: 1.0, g: 0.0, b: 0.0, a: 1.0)
      _ = #colorLiteral(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) { trailingClosure() }
      _ = #colorLiteral<SomeType>(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace '#colorLiteral' with a call to an initializer on 'NSColor' or 'UIColor'"),
        FindingSpec("2️⃣", message: "replace '#colorLiteral' with a call to an initializer on 'NSColor' or 'UIColor'"),
        FindingSpec("3️⃣", message: "replace '#colorLiteral' with a call to an initializer on 'NSColor' or 'UIColor'"),
      ]
    )
  }

  func testFileLiterals() {
    assertLint(
      NoPlaygroundLiterals.self,
      """
      _ = 1️⃣#fileLiteral(resourceName: "secrets.json")
      _ = #otherMacro(url: 2️⃣#fileLiteral(resourceName: "secrets.json"))
      _ = #otherMacro { 3️⃣#fileLiteral(resourceName: "secrets.json") }

      // Ignore invalid expansions.
      _ = #fileLiteral("secrets.json")
      _ = #fileLiteral(name: "secrets.json")
      _ = #fileLiteral(resourceName: "secrets.json") { trailingClosure() }
      _ = #fileLiteral<SomeType>(resourceName: "secrets.json")
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "replace '#fileLiteral' with a call to a method such as 'Bundle.url(forResource:withExtension:)'"
        ),
        FindingSpec(
          "2️⃣",
          message: "replace '#fileLiteral' with a call to a method such as 'Bundle.url(forResource:withExtension:)'"
        ),
        FindingSpec(
          "3️⃣",
          message: "replace '#fileLiteral' with a call to a method such as 'Bundle.url(forResource:withExtension:)'"
        ),
      ]
    )
  }

  func testImageLiterals() {
    assertLint(
      NoPlaygroundLiterals.self,
      """
      _ = 1️⃣#imageLiteral(resourceName: "image.png")
      _ = #otherMacro(url: 2️⃣#imageLiteral(resourceName: "image.png"))
      _ = #otherMacro { 3️⃣#imageLiteral(resourceName: "image.png") }

      // Ignore invalid expansions.
      _ = #imageLiteral("image.png")
      _ = #imageLiteral(name: "image.pngn")
      _ = #imageLiteral(resourceName: "image.png") { trailingClosure() }
      _ = #imageLiteral<SomeType>(resourceName: "image.png")
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace '#imageLiteral' with a call to an initializer on 'NSImage' or 'UIImage'"),
        FindingSpec("2️⃣", message: "replace '#imageLiteral' with a call to an initializer on 'NSImage' or 'UIImage'"),
        FindingSpec("3️⃣", message: "replace '#imageLiteral' with a call to an initializer on 'NSImage' or 'UIImage'"),
      ]
    )
  }
}
