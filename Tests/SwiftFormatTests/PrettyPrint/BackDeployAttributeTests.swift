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

final class BackDeployAttributeTests: PrettyPrintTestCase {
  func testSpacingAndWrapping() {
    let input =
      """
      @backDeployed(before:iOS 17)
      public func hello() {}

      @backDeployed(before:iOS  17,macOS   14)
      public func hello() {}

      @backDeployed(before:iOS  17,macOS   14,tvOS     17)
      public func hello() {}
      """

    let expected80 =
      """
      @backDeployed(before: iOS 17)
      public func hello() {}

      @backDeployed(before: iOS 17, macOS 14)
      public func hello() {}

      @backDeployed(before: iOS 17, macOS 14, tvOS 17)
      public func hello() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected28 =
      """
      @backDeployed(
        before: iOS 17
      )
      public func hello() {}

      @backDeployed(
        before: iOS 17, macOS 14
      )
      public func hello() {}

      @backDeployed(
        before:
          iOS 17, macOS 14,
          tvOS 17
      )
      public func hello() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected28, linelength: 28)
  }
}
