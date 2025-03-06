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

final class ForInStmtTests: PrettyPrintTestCase {
  func testBasicForLoop() {
    let input =
      """
      for i in mycontainer {
        let a = 123
        let b = i
      }

      for item in mylargecontainer {
        let a = 123
        let b = item
      }
      """

    let expected =
      """
      for i in mycontainer {
        let a = 123
        let b = i
      }

      for item
        in mylargecontainer
      {
        let a = 123
        let b = item
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testForWhereLoop() {
    let input =
      """
      for i in array where array.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray where longerarray.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray where longerarray.isContainer() && anotherCondition {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      for i in array where array.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray
      where longerarray.isContainer() {
        let a = 123
        let b = 456
      }
      for i in longerarray
      where longerarray.isContainer()
        && anotherCondition
      {
        let a = 123
        let b = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testForLoopFullWrap() {
    let input =
      """
      for item in aVeryLargeContainerObject where largeObject.hasProperty() && condition {
        let a = 123
        let b = 456
      }
      for item in aVeryLargeContainerObject where tinyObj.hasProperty() && condition {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      for item
        in aVeryLargeContainerObject
      where
        largeObject.hasProperty()
        && condition
      {
        let a = 123
        let b = 456
      }
      for item
        in aVeryLargeContainerObject
      where tinyObj.hasProperty()
        && condition
      {
        let a = 123
        let b = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testForLabels() {
    let input =
      """
      loopLabel: for element in container {
        let a = 123
        let b = "abc"
        if element == "" {
          continue
        }
        for c in anotherContainer {
          let d = "456"
          continue elementLoop
        }
      }
      """

    let expected =
      """
      loopLabel: for element in container {
        let a = 123
        let b = "abc"
        if element == "" {
          continue
        }
        for c in anotherContainer {
          let d = "456"
          continue elementLoop
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testForWithRanges() {
    let input =
      """
      for i in 0...10 {
        let a = 123
        print(i)
      }

      for i in 0..<10 {
        let a = 123
        print(i)
      }
      """

    let expected =
      """
      for i in 0...10 {
        let a = 123
        print(i)
      }

      for i in 0..<10 {
        let a = 123
        print(i)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testForCase() {
    let input =
      """
      for case let a as String in [] {
        let a = 123
        print(i)
      }
      """

    let expected =
      """
      for case let a
        as String in []
      {
        let a = 123
        print(i)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testForStatementWithNestedExpressions() {
    let input =
      """
      for x in someCollection where someTestableCondition && x.someProperty + x.someSpecialProperty({ $0.value }) && someOtherCondition + thatUses + operators && binPackable && exprs
      {
        let a = 42
        let foo = someFunc()
      }
      for x in someCollection
      where someTestableCondition
        && x.someProperty
          + x.someSpecialProperty({
            // comment #0
            $0.value
          })
        // comment #1
        && someOtherCondition
          // comment #2
          + thatUses + operators
        && binPackable && exprs
      {
        let a = 42
        let foo = someFunc()
      }
      """

    let expected =
      """
      for x in someCollection
      where someTestableCondition
        && x.someProperty
          + x.someSpecialProperty({
            $0.value
          })
        && someOtherCondition
          + thatUses + operators
        && binPackable && exprs
      {
        let a = 42
        let foo = someFunc()
      }
      for x in someCollection
      where someTestableCondition
        && x.someProperty
          + x.someSpecialProperty({
            // comment #0
            $0.value
          })
        // comment #1
        && someOtherCondition
          // comment #2
          + thatUses + operators
        && binPackable && exprs
      {
        let a = 42
        let foo = someFunc()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testExplicitTypeAnnotation() {
    let input =
      """
      for i: ExplicitType in mycontainer {
        let a = 123
        let b = i
      }

      for i:ExplicitType in mycontainer {
        let a = 123
        let b = i
      }

      for i: [ExplicitKeyType: ExplicitValueType] in myverylongcontainername {
        let a = 123
        let b = i
      }
      """

    let expected =
      """
      for i: ExplicitType in mycontainer {
        let a = 123
        let b = i
      }

      for i: ExplicitType in mycontainer {
        let a = 123
        let b = i
      }

      for i:
        [ExplicitKeyType: ExplicitValueType]
        in myverylongcontainername
      {
        let a = 123
        let b = i
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testTypeAnnotationIgnoresDiscretionaryNewlineAfterColon() {
    let input =
      """
      for i:
        ExplicitType in mycontainer
      {
        let a = 123
        let b = i
      }
      """

    let expected =
      """
      for i: ExplicitType in mycontainer {
        let a = 123
        let b = i
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testForAwait() {
    let input =
      """
      for await line in file {
        print(line)
      }
      """

    let expected =
      """
      for await line
        in file
      {
        print(line)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  func testForTryAwait() {
    let input =
      """
      for try await line in file {
        for try await ch in line {
          print(ch)
        }
      }
      """

    let expected =
      """
      for try await
        line in file
      {
        for
          try await
          ch in line
        {
          print(ch)
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 14)
  }
}
