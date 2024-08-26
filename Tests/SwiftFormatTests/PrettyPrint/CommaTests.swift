import SwiftFormat

final class CommaTests: PrettyPrintTestCase {
  func testArrayCommasAbsentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testArrayCommasAbsentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        1,
        2,
        3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testArrayCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testArrayCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        1,
        2,
        3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testArraySingleLineCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [1, 2, 3,]
      
      """
    
    // no effect expected
    let expected =
      """
      let MyCollection = [1, 2, 3]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testArraySingleLineCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [1, 2, 3,]
      
      """
    
    // no effect expected
    let expected =
      """
      let MyCollection = [1, 2, 3]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testArrayWithCommentCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2 // some comment
      ]

      """
    
    let expected =
      """
      let MyCollection = [
        1,
        2,  // some comment
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testArrayWithCommentCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2 // some comment
      ]

      """
    
    let expected =
      """
      let MyCollection = [
        1,
        2  // some comment
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testArrayWithTernaryOperatorAndCommentCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        true ? 1 : 2 // some comment
      ]

      """
    
    let expected =
      """
      let MyCollection = [
        1,
        true ? 1 : 2,  // some comment
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testArrayWithTernaryOperatorAndCommentCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        true ? 1 : 2 // some comment
      ]

      """
    
    let expected =
      """
      let MyCollection = [
        1,
        true ? 1 : 2  // some comment
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  func testDictionaryCommasAbsentEnabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testDictionaryCommasAbsentDisabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testDictionaryCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testDictionaryCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]
      
      """
    
    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testDictionarySingleLineCommasPresentDisabled() {
    let input =
      """
      let MyCollection = ["a": 1, "b": 2, "c": 3,]
      
      """
    
    let expected =
      """
      let MyCollection = [
        "a": 1, "b": 2, "c": 3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testDictionarySingleLineCommasPresentEnabled() {
    let input =
      """
      let MyCollection = ["a": 1, "b": 2, "c": 3,]
      
      """
    
    let expected =
      """
      let MyCollection = [
        "a": 1, "b": 2, "c": 3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
}
