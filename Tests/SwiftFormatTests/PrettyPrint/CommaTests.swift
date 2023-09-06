import SwiftFormat

final class CommaTests: PrettyPrintTestCase {
  func testCommasAbsentEnabled() {
    let input =
      """
      let MyList = [
        1,
        2,
        3
      ]
      
      """
    
    let expected =
      """
      let MyList = [
        1,
        2,
        3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multilineCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testCommasAbsentDisabled() {
    let input =
      """
      let MyList = [
        1,
        2,
        3
      ]
      
      """
    
    let expected =
      """
      let MyList = [
        1,
        2,
        3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multilineCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testCommasPresentEnabled() {
    let input =
      """
      let MyList = [
        1,
        2,
        3,
      ]
      
      """
    
    let expected =
      """
      let MyList = [
        1,
        2,
        3,
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multilineCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testCommasPresentDisabled() {
    let input =
      """
      let MyList = [
        1,
        2,
        3,
      ]
      
      """
    
    let expected =
      """
      let MyList = [
        1,
        2,
        3
      ]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multilineCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
  
  func testCommasPresentSingleLineDisabled() {
    let input =
      """
      let MyList = [1, 2, 3,]
      
      """
    
    // no effect expected
    let expected =
      """
      let MyList = [1, 2, 3]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multilineCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
  
  func testCommasPresentSingleLineEnabled() {
    let input =
      """
      let MyList = [1, 2, 3,]
      
      """
    
    // no effect expected
    let expected =
      """
      let MyList = [1, 2, 3]
      
      """
    
    var configuration = Configuration.forTesting
    configuration.multilineCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }
}
