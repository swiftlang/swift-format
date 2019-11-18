import SwiftFormatConfiguration

public class ClosureExprTests: PrettyPrintTestCase {

  public func testBasicFunctionClosures_noPackArguments() {
    let input =
      """
      funcCall(closure: <)
      funcCall(closure: { 4 })
      funcCall(closure: { $0 < $1 })
      funcCall(closure: { s1, s2 in s1 < s2 })
      funcCall(closure: { s1, s2 in return s1 < s2})
      funcCall(closure: { s1, s2, s3, s4, s5, s6 in return s1})
      funcCall(closure: { s1, s2, s3, s4, s5, s6, s7, s8, s9, s10 in return s1 })
      funcCall(param1: 123, closure: { s1, s2, s3 in return s1 })
      funcCall(closure: { (s1: String, s2: String) -> Bool in return s1 > s2 })
      """

    let expected =
      """
      funcCall(closure: <)
      funcCall(closure: { 4 })
      funcCall(closure: { $0 < $1 })
      funcCall(closure: { s1, s2 in s1 < s2 })
      funcCall(closure: { s1, s2 in
        return s1 < s2
      })
      funcCall(closure: {
        s1,
        s2,
        s3,
        s4,
        s5,
        s6 in return s1
      })
      funcCall(closure: {
        s1,
        s2,
        s3,
        s4,
        s5,
        s6,
        s7,
        s8,
        s9,
        s10 in return s1
      })
      funcCall(
        param1: 123,
        closure: { s1, s2, s3 in return s1 }
      )
      funcCall(closure: {
        (s1: String, s2: String) -> Bool in
        return s1 > s2
      })

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42, configuration: config)
  }

  public func testBasicFunctionClosures_packArguments() {
    let input =
      """
      funcCall(closure: <)
      funcCall(closure: { 4 })
      funcCall(closure: { $0 < $1 })
      funcCall(closure: { s1, s2 in s1 < s2 })
      funcCall(closure: { s1, s2 in return s1 < s2})
      funcCall(closure: { s1, s2, s3, s4, s5, s6 in return s1})
      funcCall(closure: { s1, s2, s3, s4, s5, s6, s7, s8, s9, s10 in return s1 })
      funcCall(param1: 123, closure: { s1, s2, s3 in return s1 })
      funcCall(closure: { (s1: String, s2: String) -> Bool in return s1 > s2 })
      """

    let expected =
      """
      funcCall(closure: <)
      funcCall(closure: { 4 })
      funcCall(closure: { $0 < $1 })
      funcCall(closure: { s1, s2 in s1 < s2 })
      funcCall(closure: { s1, s2 in
        return s1 < s2
      })
      funcCall(closure: {
        s1, s2, s3, s4, s5, s6 in return s1
      })
      funcCall(closure: {
        s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
        in return s1
      })
      funcCall(
        param1: 123,
        closure: { s1, s2, s3 in return s1 })
      funcCall(closure: {
        (s1: String, s2: String) -> Bool in
        return s1 > s2
      })

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42, configuration: config)
  }

  public func testTrailingClosure() {
    let input =
      """
      funcCall() { $1 < $2 }
      funcCall(param1: 2) { $1 < $2 }
      funcCall(param1: 2) { s1, s2, s3 in return s1}
      funcCall(param1: 2) { s1, s2, s3, s4, s5 in return s1}
      """

    let expected =
      """
      funcCall() { $1 < $2 }
      funcCall(param1: 2) { $1 < $2 }
      funcCall(param1: 2) { s1, s2, s3 in
        return s1
      }
      funcCall(param1: 2) {
        s1, s2, s3, s4, s5 in return s1
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  public func testClosureArgumentsWithTrailingClosure() {
    let input =
      """
      someFunc({ return s0 }) { return s2 }
      someLongerFunc({ return s0 }) { input in return s2 }
      someLongerFunc({ firstInput in someUsefulFunc(firstInput) }) { secondInput in return s2 }
      someLongerFunc({ firstInput in
        someUsefulFunc(firstInput) }) { secondInput in return someLineBreakingCall(secondInput) }
      """

    let expected =
      """
      someFunc({ return s0 }) { return s2 }
      someLongerFunc({ return s0 }) { input in
        return s2
      }
      someLongerFunc({ firstInput in
        someUsefulFunc(firstInput)
      }) { secondInput in return s2 }
      someLongerFunc({ firstInput in
        someUsefulFunc(firstInput)
      }) { secondInput in
        return someLineBreakingCall(
          secondInput)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testClosuresWithIfs() {
    let input =
    """
      let a = afunc() {
        if condition1 {
          return true
        }
        return false
      }

      let a = afunc() {
        if condition1 {
          return true
        }
        if condition2 {
          return true
        }
        return false
      }
      """

    let expected =
    """
      let a = afunc() {
        if condition1 {
          return true
        }
        return false
      }

      let a = afunc() {
        if condition1 {
          return true
        }
        if condition2 {
          return true
        }
        return false
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testClosureCapture() {
    let input =
      """
      let a = funcCall() { [weak self] (a: Int) in
        return a + 1
      }
      let a = funcCall() { [weak self, weak a = self.b] (a: Int) in
        return a + 1
      }
      let b = funcCall() { [unowned self, weak delegate = self.delegate!] (a: Int, b: String) -> String in
        return String(a) + b
      }
      """

    let expected =
      """
      let a = funcCall() { [weak self] (a: Int) in
        return a + 1
      }
      let a = funcCall() {
        [weak self, weak a = self.b] (a: Int) in
        return a + 1
      }
      let b = funcCall() {
        [unowned self, weak delegate = self.delegate!]
        (a: Int, b: String) -> String in
        return String(a) + b
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testClosureCaptureWithoutArguments() {
    let input =
      """
      let a = { [weak self] in return foo }
      """

    let expected =
      """
      let a = { [weak self] in
        return foo
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testBodilessClosure() {
    let input =
      """
      let a = funcCall() { s1, s2 in
        // Move along, nothing here to see
      }
      let a = funcCall() { s1, s2 in }
      let a = funcCall() {}
      """

    let expected =
      """
      let a = funcCall() { s1, s2 in
        // Move along, nothing here to see
      }
      let a = funcCall() { s1, s2 in }
      let a = funcCall() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testClosureVariables() {
    let input =
      """
      var someClosure: (Int, Int, Int) -> Bool = {  // a comment
        (a, b, c) in
        foo()
        return true
      }
      var someOtherClosure: (Int, Int, Int) -> Bool = {
        foo($0, $1, $2)
        return true
      }
      class Bar {
        private lazy var foo = { Foo() }()
      }
      class Foo {
        private lazy var bar = {
          // do some computations
          return Bar()
        }()
      }
      """
    let expected =
      """
      var someClosure: (Int, Int, Int) -> Bool = {  // a comment
        (a, b, c) in
        foo()
        return true
      }
      var someOtherClosure: (Int, Int, Int) -> Bool = {
        foo($0, $1, $2)
        return true
      }
      class Bar {
        private lazy var foo = { Foo() }()
      }
      class Foo {
        private lazy var bar = {
          // do some computations
          return Bar()
        }()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  public func testArrayClosures() {
    let input =
      """
      let a = [ { a, b in someFunc(a, b) } ]
      """

    let expected =
      """
      let a = [{ a, b in someFunc(a, b) }]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }
}
