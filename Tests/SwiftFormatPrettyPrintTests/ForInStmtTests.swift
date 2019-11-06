public class ForInStmtTests: PrettyPrintTestCase {
  public func testBasicForLoop() {
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

  public func testForWhereLoop() {
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

  public func testForLoopFullWrap() {
    let input =
      """
      for item in aVeryLargeContainterObject where largeObject.hasProperty() && condition {
        let a = 123
        let b = 456
      }
      for item in aVeryLargeContainterObject where tinyObj.hasProperty() && condition {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      for item
        in aVeryLargeContainterObject
      where
        largeObject.hasProperty()
        && condition
      {
        let a = 123
        let b = 456
      }
      for item
        in aVeryLargeContainterObject
      where tinyObj.hasProperty()
        && condition
      {
        let a = 123
        let b = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testForLabels() {
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

  public func testForWithRanges() {
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

  public func testForCase() {
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

  public func testForStatementWithNestedExpressions() {
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

    // FIXME: Based on the way that continuations are now handled, it's not clear that we can
    // get `// comment #2` indented correctly based on what comes *after* it. I think the right
    // approach here is to change the handling of full-line comments (and probably doc-comments as
    // well) so that they are deferred until either just before the next text token is printed or
    // the next close-break. But this is a larger change that I'll revisit in a separate PR.
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
}
