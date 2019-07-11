import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class OrderedImportsTests: DiagnosingTestCase {
  public func testInvalidImportsOrder() {
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
  
  public func testImportsOrderWithoutModuleType() {
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
  
  public func testImportsOrderWithDocComment() {
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
  
  public func testValidOrderedImport() {
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

  public func testSeparatedFileHeader() {
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

  public func testNonHeaderComment() {
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

  public func testDisableOrderedImports() {
    let input =
      """
      import C
      import B
      // swift-format-disable: OrderedImports
      import A
      // swift-format-enable: OrderedImports
      let a = 123
      import func Darwin.C.isatty
      """

    let expected =
      """
      import B
      import C

      import func Darwin.C.isatty

      // swift-format-disable: OrderedImports
      import A
      // swift-format-enable: OrderedImports
      let a = 123
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // import Aimport
    XCTAssertDiagnosed(.sortImports)

    // import func Darwin.C.isatty
    XCTAssertDiagnosed(.placeAtTopOfFile)
  }

  public func testDisableOrderedImportsMovingComments() {
    let input =
      """
      import B
      import C
      // swift-format-disable: OrderedImports
      import A
      // swift-format-enable: OrderedImports
      import D
      """

    let expected =
      """
      import B
      import C
      // swift-format-enable: OrderedImports
      import D

      // swift-format-disable: OrderedImports
      import A
      """

    XCTAssertFormatting(
      OrderedImports.self, input: input, expected: expected, checkForUnassertedDiagnostics: true
    )

    // import D
    XCTAssertDiagnosed(.placeAtTopOfFile)
  }

  public func testEmptyFile() {
    XCTAssertFormatting(
      OrderedImports.self, input: "", expected: "", checkForUnassertedDiagnostics: true
    )
    XCTAssertFormatting(
      OrderedImports.self, input: "// test", expected: "// test",
      checkForUnassertedDiagnostics: true
    )
  }
}
