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

final class AvailabilityConditionTests: PrettyPrintTestCase {
  func testAvailabilityCondition() {
    let input =
      """
      if someCondition {
      if something, #available(OSX 10.12, *) {
      let a = 123
      let b = "abc"
      }
      }

      if someCondition {
            if something, #available(OSX 10.12, *) {
         let a = 123
      let b = "abc"
            }
      }

      if someCondition {
        if anotherCondition {
      if something, #available(OSX 10.12, *) {
        let a = 123
        let b = "abc"
      }
        }
      }

      if #available(OSX 10.12, *) {
        // Do stuff
      } else {
        let a = 123
        let b = "abc"
      }

      #if canImport(os)
        if #available(OSX 10.12, *) {
          // Do stuff
        } else {
          let a = 123
          let b = "abc"
        }
      #endif

      func myfun() {

        if #available(OSX 10.12, *) {

          let a = 123
        } else {
          // do stuff
        }
      }
      """

    let expected =
      """
      if someCondition {
        if something, #available(OSX 10.12, *) {
          let a = 123
          let b = "abc"
        }
      }

      if someCondition {
        if something, #available(OSX 10.12, *) {
          let a = 123
          let b = "abc"
        }
      }

      if someCondition {
        if anotherCondition {
          if something, #available(OSX 10.12, *) {
            let a = 123
            let b = "abc"
          }
        }
      }

      if #available(OSX 10.12, *) {
        // Do stuff
      } else {
        let a = 123
        let b = "abc"
      }

      #if canImport(os)
        if #available(OSX 10.12, *) {
          // Do stuff
        } else {
          let a = 123
          let b = "abc"
        }
      #endif

      func myfun() {

        if #available(OSX 10.12, *) {

          let a = 123
        } else {
          // do stuff
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testAvailabilityConditionWithTrailingComment() {
    let input =
      """
      struct MyStruct {
        #if swift(>=4.2)
          // Do stuff here
        #endif  // trailing comment

        let someMemberVar: Int
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }
}
