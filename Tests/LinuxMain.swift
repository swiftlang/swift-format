import XCTest

import CommonMarkTests
import SwiftFormatCoreTests
import SwiftFormatPrettyPrintTests
import SwiftFormatRulesTests
import SwiftFormatWhitespaceLinterTests

var tests = [XCTestCaseEntry]()
tests += CommonMarkTests.__allTests()
tests += SwiftFormatCoreTests.__allTests()
tests += SwiftFormatPrettyPrintTests.__allTests()
tests += SwiftFormatRulesTests.__allTests()
tests += SwiftFormatWhitespaceLinterTests.__allTests()

XCTMain(tests)
