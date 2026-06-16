//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class SwiftTestingNamingConventionsTests: LintOrFormatRuleTestCase {
  /// A configuration where all Swift Testing naming convention rules are explicitly enabled.
  private var enabledConfig: Configuration {
    var config = Configuration.forTesting(enabledRule: SwiftTestingNamingConventions.ruleName)
    config.swiftTestingNamingConventions.forbidSuiteWithoutParameters = true
    config.swiftTestingNamingConventions.forbidSuiteDescription = true
    config.swiftTestingNamingConventions.forbidTestDescription = true
    config.swiftTestingNamingConventions.requireRawIdentifierTestNames = true
    return config
  }

  func testEmptySuiteAttribute() {
    assertLint(
      SwiftTestingNamingConventions.self,
      """
      1️⃣@Suite class MyTests {}
      2️⃣@Suite() class MyOtherTests {}
      3️⃣@Testing.Suite class MyThirdTests {}
      4️⃣@Testing.Suite() class MyFourthTests {}
      @SomeOtherModule.Suite() class MyFifthTests {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@Suite' attribute when it is empty"),
        FindingSpec("2️⃣", message: "remove '@Suite' attribute when it is empty"),
        FindingSpec("3️⃣", message: "remove '@Suite' attribute when it is empty"),
        FindingSpec("4️⃣", message: "remove '@Suite' attribute when it is empty"),
      ],
      configuration: enabledConfig
    )
  }

  func testSuiteWithArgumentsIsAllowed() {
    assertLint(
      SwiftTestingNamingConventions.self,
      """
      @Suite(.serialized) class MyTests {}
      @Suite(tags: ["foo"]) class MyOtherTests {}
      """,
      findings: [],
      configuration: enabledConfig
    )
  }

  func testSuiteStringDescriptionViolation() {
    assertLint(
      SwiftTestingNamingConventions.self,
      """
      1️⃣@Suite("My Custom Suite Name") class MyTests {}
      2️⃣@Testing.Suite("My Custom Suite Name") class MyOtherTests {}
      3️⃣@Suite("My Custom Suite Name", .serialized) class MyThirdTests {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the string description from '@Suite'"),
        FindingSpec("2️⃣", message: "remove the string description from '@Suite'"),
        FindingSpec("3️⃣", message: "remove the string description from '@Suite'"),
      ],
      configuration: enabledConfig
    )
  }

  func testEmptySuiteAllowedButDescriptionNotAllowed() {
    var config = Configuration.forTesting(enabledRule: SwiftTestingNamingConventions.ruleName)
    config.swiftTestingNamingConventions.forbidSuiteDescription = true
    config.swiftTestingNamingConventions.forbidSuiteWithoutParameters = false

    assertLint(
      SwiftTestingNamingConventions.self,
      """
      @Suite class MyTests {}
      @Suite() class MyOtherTests {}
      @Testing.Suite class MyThirdTests {}
      1️⃣@Suite("My Custom Suite Name") class MyFourthTests {}
      2️⃣@Suite("My Custom Suite Name", .serialized) class MyFifthTests {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the string description from '@Suite'"),
        FindingSpec("2️⃣", message: "remove the string description from '@Suite'"),
      ],
      configuration: config
    )
  }

  func testDescriptionAllowedButEmptySuiteNotAllowed() {
    var config = Configuration.forTesting(enabledRule: SwiftTestingNamingConventions.ruleName)
    config.swiftTestingNamingConventions.forbidSuiteDescription = false
    config.swiftTestingNamingConventions.forbidSuiteWithoutParameters = true

    assertLint(
      SwiftTestingNamingConventions.self,
      """
      1️⃣@Suite class MyTests {}
      2️⃣@Suite() class MyOtherTests {}
      3️⃣@Testing.Suite class MyThirdTests {}
      @Suite("My Custom Suite Name") class MyFourthTests {}
      @Suite("My Custom Suite Name", .serialized) class MyFifthTests {}
      @Suite(.serialized) class MySixthTests {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@Suite' attribute when it is empty"),
        FindingSpec("2️⃣", message: "remove '@Suite' attribute when it is empty"),
        FindingSpec("3️⃣", message: "remove '@Suite' attribute when it is empty"),
      ],
      configuration: config
    )
  }

  func testTestFunctionNameIsRawIdentifier() {
    assertLint(
      SwiftTestingNamingConventions.self,
      """
      @Test func 1️⃣testSomething() {}
      @Test func `some test name`() {}
      @Testing.Test func `another test`() {}
      @Testing.Test func 2️⃣anotherTest() {}
      @SomeOther.Test func anotherTest() {}
      func `non test function`() {}
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "convert test function 'testSomething' to a space-separated description surrounded by backticks"
        ),
        FindingSpec(
          "2️⃣",
          message: "convert test function 'anotherTest' to a space-separated description surrounded by backticks"
        ),
      ],
      configuration: enabledConfig
    )
  }

  func testTestStringDescriptionViolation() {
    assertLint(
      SwiftTestingNamingConventions.self,
      """
      1️⃣@Test("My Custom Test Name") func `testSomething`() {}
      2️⃣@Testing.Test("My Custom Test Name") func `testOther`() {}
      3️⃣@Test("My Custom Test Name", .disabled("reason")) func `testThird`() {}
      @Test(.disabled("reason")) func `testFourth`() {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the string description from '@Test'"),
        FindingSpec("2️⃣", message: "remove the string description from '@Test'"),
        FindingSpec("3️⃣", message: "remove the string description from '@Test'"),
      ],
      configuration: enabledConfig
    )
  }

  func testConfigurationsCanDisableViolations() {
    var config = Configuration.forTesting(enabledRule: SwiftTestingNamingConventions.ruleName)
    config.swiftTestingNamingConventions.forbidSuiteWithoutParameters = false
    config.swiftTestingNamingConventions.forbidSuiteDescription = false
    config.swiftTestingNamingConventions.forbidTestDescription = false
    config.swiftTestingNamingConventions.requireRawIdentifierTestNames = false

    assertLint(
      SwiftTestingNamingConventions.self,
      """
      @Suite class MyTests {}
      @Suite() class MyOtherTests {}
      @Suite("My Custom Suite Name") class MyThirdTests {}
      @Test func testSomething() {}
      @Test("My Custom Test Name") func testOther() {}
      """,
      findings: [],
      configuration: config
    )
  }

  func testDefaultConfigurationIsDisabled() {
    // Verify that by default, when no configurations are explicitly modified, all of these
    // violations are ignored.
    assertLint(
      SwiftTestingNamingConventions.self,
      """
      @Suite class MyTests {}
      @Suite() class MyOtherTests {}
      @Suite("My Custom Suite Name") class MyThirdTests {}
      @Test func testSomething() {}
      @Test("My Custom Test Name") func testOther() {}
      """,
      findings: []
    )
  }
}
