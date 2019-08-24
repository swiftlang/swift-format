import SwiftSyntax

public class ApplicationRangeTests: PrettyPrintTestCase {
  public func testFormatNestedFunc() {
    let input =
      """
      /// this is doc comment
      ///
      /// another line
      struct X {
      func f() {
      func g() {}
      }
      }
      """

    let expected =
      """
      /// this is doc comment
      ///
      /// another line
      struct X {
      func f() {
        func g() {}
      }
      }
      """

    assertPrettyPrintEqual(input: input,
                           expected: expected,
                           linelength: 45,
                           applicationRangeBuilder: { sourceFileSyntax in
      let startRange = SourceLocation(offset: 67, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      let endRange = SourceLocation(offset: 78, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      return SourceRange(start: startRange, end: endRange)
    })
  }

  public func testFormatBothNestedFuncs() {
    let input =
      """
      struct X {
      func f() {
      func g() {}
      }
      }
      """

    let expected =
      """
      struct X {
        func f() {
          func g() {}
        }
      }
      """

    assertPrettyPrintEqual(input: input,
                           expected: expected,
                           linelength: 45,
                           applicationRangeBuilder: { sourceFileSyntax in
      let startRange = SourceLocation(offset: 11, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      let endRange = SourceLocation(offset: 34, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      return SourceRange(start: startRange, end: endRange)
    })
  }
  
  public func testFormatWholeFileWithRange_isSameAsWithoutRangeSpecified() {
    let input =
      """
      struct X {
      func f() {
      func g() {}
      }
      }
      """

    let expected =
      """
      struct X {
        func f() {
          func g() {}
        }
      }
      """

    assertPrettyPrintEqual(input: input,
                           expected: expected,
                           linelength: 45,
                           applicationRangeBuilder: { sourceFileSyntax in
      let startRange = SourceLocation(offset: 0, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      let endRange = SourceLocation(offset: 37, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      return SourceRange(start: startRange, end: endRange)
    })
  }
  
  public func testFormatNothingInAlreadyFormatedCode() {
    let input =
    """
    struct X {
      let y: Int
    }
    """
    
    let expected =
    """
    struct X {
      let y: Int
    }
    """
    
    assertPrettyPrintEqual(input: input,
                           expected: expected,
                           linelength: 45,
                           applicationRangeBuilder: { sourceFileSyntax in
      let startRange = SourceLocation(offset: 0, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      let endRange = SourceLocation(offset: 25, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      return SourceRange(start: startRange, end: endRange)
    })
  }
  
  // This test fails ;(
  public func testFormatOneStruct() {
    let input =
      """
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { get { return memberValue + 2 } set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      """

    let expected =
      """
      struct MyStruct {
        var memberValue: Int
        var someValue: Int {
          get { return memberValue + 2 }
          set(newValue) { memberValue = newValue }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      """

    assertPrettyPrintEqual(input: input,
                           expected: expected,
                           linelength: 45,
                           applicationRangeBuilder: { sourceFileSyntax in
      let startRange = SourceLocation(offset: 0, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      let endRange = SourceLocation(offset: 140, converter: SourceLocationConverter(file: "", tree: sourceFileSyntax))
      return SourceRange(start: startRange, end: endRange)
    })
  }
}
