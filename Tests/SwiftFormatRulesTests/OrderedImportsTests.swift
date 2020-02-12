import SwiftFormatRules

final class OrderedImportsTests: LintOrFormatRuleTestCase {
  func testInvalidImportsOrder() {
    let input =
      """
      import Foundation
      // Starts Imports
      import Core


      // Comment with new lines
      import UIKit

      @testable import SwiftFormatRules
      import enum Darwin.D.isatty
      // Starts Test
      @testable import MyModuleUnderTest
      // Starts Ind
      import func Darwin.C.isatty

      let a = 3
      import SwiftSyntax
      """

    let expected =
      """
      // Starts Imports
      import Core
      import Foundation
      import SwiftSyntax
      // Comment with new lines
      import UIKit

      // Starts Ind
      import func Darwin.C.isatty
      import enum Darwin.D.isatty

      // Starts Test
      @testable import MyModuleUnderTest
      @testable import SwiftFormatRules

      let a = 3
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    XCTAssertDiagnosed(.sortImports)  // import Core
    XCTAssertDiagnosed(.sortImports)  // import func Darwin.C.isatty
    XCTAssertDiagnosed(.sortImports)  // @testable import MyModuleUnderTest

    // import SwiftSyntax
    XCTAssertDiagnosed(.placeAtTopOfFile)
    XCTAssertDiagnosed(.groupImports(before: .regularImport, after: .declImport))
    XCTAssertDiagnosed(.groupImports(before: .regularImport, after: .testableImport))

    // import func Darwin.C.isatty
    XCTAssertDiagnosed(.groupImports(before: .declImport, after: .testableImport))

    // import enum Darwin.D.isatty
    XCTAssertDiagnosed(.groupImports(before: .declImport, after: .testableImport))
  }
  
  func testImportsOrderWithoutModuleType() {
    let input =
      """
      @testable import SwiftFormatRules
      import func Darwin.D.isatty
      @testable import MyModuleUnderTest
      import func Darwin.C.isatty

      let a = 3
      """

    let expected =
      """
      import func Darwin.C.isatty
      import func Darwin.D.isatty

      @testable import MyModuleUnderTest
      @testable import SwiftFormatRules

      let a = 3
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // import func Darwin.D.isatty
    XCTAssertDiagnosed(.groupImports(before: .declImport, after: .testableImport))

    // import func Darwin.C.isatty
    XCTAssertDiagnosed(.groupImports(before: .declImport, after: .testableImport))
    XCTAssertDiagnosed(.sortImports)

    // @testable import MyModuleUnderTest
    XCTAssertDiagnosed(.sortImports)
  }
  
  func testImportsOrderWithDocComment() {
    let input =
      """
      /// Test imports with comments.
      ///
      /// Comments at the top of the file
      /// should be preserved.

      // Line comment for import
      // Foundation.
      import Foundation
      // Line comment for Core
      import Core
      import UIKit

      let a = 3
      """

    let expected =
      """
      /// Test imports with comments.
      ///
      /// Comments at the top of the file
      /// should be preserved.

      // Line comment for Core
      import Core
      // Line comment for import
      // Foundation.
      import Foundation
      import UIKit

      let a = 3
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // import Core
    XCTAssertDiagnosed(.sortImports)
  }
  
  func testValidOrderedImport() {
    let input =
      """
      import CoreLocation
      import MyThirdPartyModule
      import SpriteKit
      import UIKit

      import func Darwin.C.isatty

      @testable import MyModuleUnderTest
      """

    let expected =
      """
      import CoreLocation
      import MyThirdPartyModule
      import SpriteKit
      import UIKit

      import func Darwin.C.isatty

      @testable import MyModuleUnderTest
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // Should not raise any linter errors.
  }

  func testSeparatedFileHeader() {
    let input =
      """
      // This is part of the file header.

      // So is this.

      // Top comment
      import Bimport
      import Aimport

      struct MyStruct {
        // do stuff
      }

      import HoistMe
      """

    let expected =
      """
      // This is part of the file header.

      // So is this.

      import Aimport
      // Top comment
      import Bimport
      import HoistMe

      struct MyStruct {
        // do stuff
      }
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // import Aimport
    XCTAssertDiagnosed(.sortImports)

    // import HoistMe
    XCTAssertDiagnosed(.placeAtTopOfFile)
  }

  func testNonHeaderComment() {
    let input =
      """
      // Top comment
      import Bimport
      import Aimport

      let A = 123
      """

    let expected =
      """
      import Aimport
      // Top comment
      import Bimport

      let A = 123
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // import Aimport
    XCTAssertDiagnosed(.sortImports)
  }

  func testMultipleCodeBlocksPerLine() {
    let input =
      """
      import A;import Z;import D;import C;
      foo();bar();baz();quxxe();
      """

    let expected =
      """
      import A;
      import C;
      import D;
      import Z;

      foo();bar();baz();quxxe();
      """

    XCTAssertFormatting(OrderedImports.self, input: input, expected: expected)
  }

  func testMultipleCodeBlocksWithImportsPerLine() {
    let input =
      """
      import A;import Z;import D;import C;foo();bar();baz();quxxe();
      """

    let expected =
      """
      import A;
      import C;
      import D;
      import Z;

      foo();bar();baz();quxxe();
      """

    XCTAssertFormatting(OrderedImports.self, input: input, expected: expected)
  }

  func testDisableOrderedImports() {
    let input =
      """
      import C
      import B
      // swift-format-ignore: OrderedImports
      import A
      let a = 123
      import func Darwin.C.isatty

      // swift-format-ignore
      import a
      """

    let expected =
      """
      import B
      import C

      // swift-format-ignore: OrderedImports
      import A

      import func Darwin.C.isatty

      let a = 123

      // swift-format-ignore
      import a
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    XCTAssertDiagnosed(.sortImports, line: 2, column: 1)
    XCTAssertDiagnosed(.placeAtTopOfFile, line: 6, column: 1)
  }

  func testDisableOrderedImportsMovingComments() {
    let input =
      """
      import C  // Trailing comment about C
      import B
      // Comment about ignored A
      // swift-format-ignore: OrderedImports
      import A  // trailing comment about ignored A
      // Comment about Z
      import Z
      import D
      // swift-format-ignore
      // Comment about testable testA
      @testable import testA
      @testable import testZ  // trailing comment about testZ
      @testable import testC
      // swift-format-ignore
      @testable import testB
      // Comment about Bar
      import enum Bar

      let a = 2
      """

    let expected =
      """
      import B
      import C  // Trailing comment about C

      // Comment about ignored A
      // swift-format-ignore: OrderedImports
      import A  // trailing comment about ignored A

      import D
      // Comment about Z
      import Z

      // swift-format-ignore
      // Comment about testable testA
      @testable import testA

      @testable import testC
      @testable import testZ  // trailing comment about testZ

      // swift-format-ignore
      @testable import testB

      // Comment about Bar
      import enum Bar

      let a = 2
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    XCTAssertDiagnosed(.sortImports, line: 2, column: 1)
    XCTAssertDiagnosed(.sortImports, line: 8, column:  1)
    XCTAssertDiagnosed(.sortImports, line: 13, column: 1)
  }

  func testEmptyFile() {
    XCTAssertFormatting(
      OrderedImports.self, input: "", expected: "", checkForUnassertedDiagnostics: true
    )
    XCTAssertFormatting(
      OrderedImports.self, input: "// test", expected: "// test",
      checkForUnassertedDiagnostics: true
    )
  }
}
