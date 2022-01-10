import SwiftFormatRules

final class ValidateDocumentationCommentsTests: LintOrFormatRuleTestCase {
  override func setUp() {
    super.setUp()
    shouldCheckForUnassertedDiagnostics = true
  }

  func testParameterDocumentation() {
    let input =
    """
    /// Uses 'Parameters' when it only has one parameter.
    ///
    /// - Parameters singular: singular description.
    /// - Returns: A string containing the contents of a
    ///   description
    func testPluralParamDesc(singular: String) -> Bool {}

    /// Uses 'Parameter' with a list of parameters.
    ///
    /// - Parameter
    ///   - command: The command to execute in the shell environment.
    ///   - stdin: The string to use as standard input.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func execute(command: String, stdin: String) -> String {
    // ...
    }

    /// Returns the output generated by executing a command with the given string
    /// used as standard input.
    ///
    /// - Parameter command: The command to execute in the shell environment.
    /// - Parameter stdin: The string to use as standard input.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func testInvalidParameterDesc(command: String, stdin: String) -> String {}
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertDiagnosed(.useSingularParameter, line: 6, column: 1)
    XCTAssertDiagnosed(.usePluralParameters, line: 15, column: 1)
    XCTAssertDiagnosed(.usePluralParameters, line: 26, column: 1)
  }

  func testParametersName() {
    let input =
    """
    /// Parameters dont match.
    ///
    /// - Parameters:
    ///   - sum: The sum of all numbers.
    ///   - avg: The average of all numbers.
    /// - Returns: The sum of sum and avg.
    func sum(avg: Int, sum: Int) -> Int {}

    /// Missing one parameter documentation.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    /// - Returns: an integer.
    func foo(p1: Int, p2: Int, p3: Int) -> Int {}
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertDiagnosed(.parametersDontMatch(funcName: "sum"), line: 7, column: 1)
    XCTAssertDiagnosed(.parametersDontMatch(funcName: "foo"), line: 15, column: 1)
  }

  func testThrowsDocumentation() {
    let input =
    """
    /// One sentence summary.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    ///   - p3: Parameter 3.
    /// - Throws: an error.
    func doesNotThrow(p1: Int, p2: Int, p3: Int) {}

    /// One sentence summary.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    ///   - p3: Parameter 3.
    func doesThrow(p1: Int, p2: Int, p3: Int) throws {}

    /// One sentence summary.
    ///
    /// - Parameter p1: Parameter 1.
    /// - Throws: doesn't really throw, just rethrows
    func doesRethrow(p1: (() throws -> ())) rethrows {}
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertDiagnosed(.removeThrowsComment(funcName: "doesNotThrow"), line: 8, column: 1)
    XCTAssertDiagnosed(.documentErrorsThrown(funcName: "doesThrow"), line: 16, column: 43)
    XCTAssertDiagnosed(.removeThrowsComment(funcName: "doesRethrow"), line: 22, column: 41)
  }

  func testReturnDocumentation() {
    let input =
    """
    /// One sentence summary.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    ///   - p3: Parameter 3.
    /// - Returns: an integer.
    func noReturn(p1: Int, p2: Int, p3: Int) {}

    /// One sentence summary.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    ///   - p3: Parameter 3.
    func foo(p1: Int, p2: Int, p3: Int) -> Int {}

    /// One sentence summary.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    ///   - p3: Parameter 3.
    func neverReturns(p1: Int, p2: Int, p3: Int) -> Never {}

    /// One sentence summary.
    ///
    /// - Parameters:
    ///   - p1: Parameter 1.
    ///   - p2: Parameter 2.
    ///   - p3: Parameter 3.
    /// - Returns: Never returns.
    func documentedNeverReturns(p1: Int, p2: Int, p3: Int) -> Never {}
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertDiagnosed(.removeReturnComment(funcName: "noReturn"), line: 8, column: 1)
    XCTAssertDiagnosed(.documentReturnValue(funcName: "foo"), line: 16, column: 37)
    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "neverReturns"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "documentedNeverReturns"))
  }

  func testValidDocumentation() {
    let input =
    """
    /// Returns the output generated by executing a command.
    ///
    /// - Parameter command: The command to execute in the shell environment.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func singularParam(command: String) -> String {
    // ...
    }

    /// Returns the output generated by executing a command with the given string
    /// used as standard input.
    ///
    /// - Parameters:
    ///   - command: The command to execute in the shell environment.
    ///   - stdin: The string to use as standard input.
    /// - Throws: An error, possibly.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func pluralParam(command: String, stdin: String) throws -> String {
    // ...
    }

    /// One sentence summary.
    ///
    /// - Parameter p1: Parameter 1.
    func rethrower(p1: (() throws -> ())) rethrows {
    // ...
    }

    /// Parameter(s) and Returns tags may be omitted only if the single-sentence
    /// brief summary fully describes the meaning of those items and including the
    /// tags would only repeat what has already been said
    func ommitedFunc(p1: Int)
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertNotDiagnosed(.useSingularParameter)
    XCTAssertNotDiagnosed(.usePluralParameters)

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "singularParam"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "singularParam"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "singularParam"))

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.documentErrorsThrown(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.removeThrowsComment(funcName: "pluralParam"))

    XCTAssertNotDiagnosed(.documentErrorsThrown(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.removeThrowsComment(funcName: "pluralParam"))

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "ommitedFunc"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "ommitedFunc"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "ommitedFunc"))
  }

  func testSeparateLabelAndIdentifier() {
    let input =
    """
    /// Returns the output generated by executing a command.
    ///
    /// - Parameter command: The command to execute in the shell environment.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func incorrectParam(label commando: String) -> String {
    // ...
    }

    /// Returns the output generated by executing a command.
    ///
    /// - Parameter command: The command to execute in the shell environment.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func singularParam(label command: String) -> String {
    // ...
    }

    /// Returns the output generated by executing a command with the given string
    /// used as standard input.
    ///
    /// - Parameters:
    ///   - command: The command to execute in the shell environment.
    ///   - stdin: The string to use as standard input.
    /// - Returns: A string containing the contents of the invoked process's
    ///   standard output.
    func pluralParam(label command: String, label2 stdin: String) -> String {
    // ...
    }
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertNotDiagnosed(.useSingularParameter)
    XCTAssertNotDiagnosed(.usePluralParameters)

    XCTAssertDiagnosed(.parametersDontMatch(funcName: "incorrectParam"), line: 6, column: 1)

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "singularParam"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "singularParam"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "singularParam"))

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "pluralParam"))
  }

  func testInitializer() {
    let input =
    """
    struct SomeType {
      /// Brief summary.
      ///
      /// - Parameter command: The command to execute in the shell environment.
      /// - Returns: Shouldn't be here.
      init(label commando: String) {
      // ...
      }

      /// Brief summary.
      ///
      /// - Parameter command: The command to execute in the shell environment.
      init(label command: String) {
      // ...
      }

      /// Brief summary.
      ///
      /// - Parameters:
      ///   - command: The command to execute in the shell environment.
      ///   - stdin: The string to use as standard input.
      init(label command: String, label2 stdin: String) {
      // ...
      }

      /// Brief summary.
      ///
      /// - Parameters:
      ///   - command: The command to execute in the shell environment.
      ///   - stdin: The string to use as standard input.
      /// - Throws: An error.
      init(label command: String, label2 stdin: String) throws {
      // ...
      }
    }
    """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertNotDiagnosed(.useSingularParameter)
    XCTAssertNotDiagnosed(.usePluralParameters)

    XCTAssertDiagnosed(.parametersDontMatch(funcName: "init"), line: 6, column: 3)
    XCTAssertDiagnosed(.removeReturnComment(funcName: "init"), line: 6, column: 3)

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "init"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "init"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "init"))

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "init"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "init"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "init"))

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "init"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "init"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "init"))
    XCTAssertNotDiagnosed(.documentErrorsThrown(funcName: "init"))
    XCTAssertNotDiagnosed(.removeThrowsComment(funcName: "init"))
  }

  func testValidateTagsEvenSingleSentence() {
    let input =
      """
      /// Returns the output generated by executing a command
      ///
      /// - Parameter command: The command to execute in the shell environment.
      func singularParam(command: String) -> String {
      // ...
      }

      /// Returns the output generated by executing a command with the given string
      /// used as standard input
      ///
      /// - Parameters:
      ///   - command: The command to execute in the shell environment.
      ///   - stdin: The string to use as standard input.
      /// - Returns: A string containing the contents of the invoked process's
      ///   standard output.
      func pluralParam(command: String, stdin: String) throws -> String {
      // ...
      }

      /// One sentence summary
      ///
      /// - Parameter p1: Parameter 1.
      func rethrower(p2: (() throws -> ())) rethrows {
      // ...
      }
      """
    performLint(ValidateDocumentationComments.self, input: input)
    XCTAssertNotDiagnosed(.useSingularParameter)
    XCTAssertNotDiagnosed(.usePluralParameters)

    XCTAssertDiagnosed(.documentReturnValue(funcName: "singularParam"), line: 4, column: 37)
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "singularParam"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "singularParam"))

    XCTAssertNotDiagnosed(.documentReturnValue(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.removeReturnComment(funcName: "pluralParam"))
    XCTAssertNotDiagnosed(.parametersDontMatch(funcName: "pluralParam"))
    XCTAssertDiagnosed(.documentErrorsThrown(funcName: "pluralParam"), line: 16, column: 50)
    XCTAssertNotDiagnosed(.removeThrowsComment(funcName: "pluralParam"))

    XCTAssertDiagnosed(.parametersDontMatch(funcName: "rethrower"), line: 23, column: 1)
    XCTAssertNotDiagnosed(.removeThrowsComment(funcName: "rethrower"))
  }
}
