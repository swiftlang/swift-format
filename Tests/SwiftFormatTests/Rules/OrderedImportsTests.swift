@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class OrderedImportsTests: LintOrFormatRuleTestCase {
  func testInvalidImportsOrder() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import Foundation
        // Starts Imports
        1️⃣import Core


        // Comment with new lines
        import UIKit

        @testable import SwiftFormat
        8️⃣import enum Darwin.D.isatty
        // Starts Test
        3️⃣@testable import MyModuleUnderTest
        // Starts Ind
        2️⃣7️⃣import func Darwin.C.isatty

        let a = 3
        4️⃣5️⃣6️⃣import SwiftSyntax
        """,
      expected: """
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
        @testable import SwiftFormat

        let a = 3
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically"),
        FindingSpec("2️⃣", message: "place declaration imports before testable imports"),
        FindingSpec("3️⃣", message: "sort import statements lexicographically"),
        FindingSpec("4️⃣", message: "place imports at the top of the file"),
        FindingSpec("5️⃣", message: "place regular imports before testable imports"),
        FindingSpec("6️⃣", message: "place regular imports before declaration imports"),
        FindingSpec("7️⃣", message: "sort import statements lexicographically"),
        FindingSpec("8️⃣", message: "place declaration imports before testable imports"),
      ]
    )
  }

  func testImportsOrderWithoutModuleType() {
    assertFormatting(
      OrderedImports.self,
      input: """
        @testable import SwiftFormat
        1️⃣import func Darwin.D.isatty
        4️⃣@testable import MyModuleUnderTest
        2️⃣3️⃣import func Darwin.C.isatty

        let a = 3
        """,
      expected: """
        import func Darwin.C.isatty
        import func Darwin.D.isatty

        @testable import MyModuleUnderTest
        @testable import SwiftFormat

        let a = 3
        """,
      findings: [
        FindingSpec("1️⃣", message: "place declaration imports before testable imports"),
        FindingSpec("2️⃣", message: "place declaration imports before testable imports"),
        FindingSpec("3️⃣", message: "sort import statements lexicographically"),
        FindingSpec("4️⃣", message: "sort import statements lexicographically"),
      ]
    )
  }

  func testImportsOrderWithDocComment() {
    assertFormatting(
      OrderedImports.self,
      input: """
        /// Test imports with comments.
        ///
        /// Comments at the top of the file
        /// should be preserved.

        // Line comment for import
        // Foundation.
        import Foundation
        // Line comment for Core
        1️⃣import Core
        import UIKit

        let a = 3
        """,
      expected: """
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }

  func testValidOrderedImport() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import CoreLocation
        import MyThirdPartyModule
        import SpriteKit
        import UIKit

        import func Darwin.C.isatty

        @testable import MyModuleUnderTest
        """,
      expected: """
        import CoreLocation
        import MyThirdPartyModule
        import SpriteKit
        import UIKit

        import func Darwin.C.isatty

        @testable import MyModuleUnderTest
        """,
      findings: []
    )
  }

  func testSeparatedFileHeader() {
    assertFormatting(
      OrderedImports.self,
      input: """
        // This is part of the file header.

        // So is this.

        // Top comment
        import Bimport
        1️⃣import Aimport

        struct MyStruct {
          // do stuff
        }

        2️⃣import HoistMe
        """,
      expected: """
        // This is part of the file header.

        // So is this.

        import Aimport
        // Top comment
        import Bimport
        import HoistMe

        struct MyStruct {
          // do stuff
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically"),
        FindingSpec("2️⃣", message: "place imports at the top of the file"),
      ]
    )
  }

  func testNonHeaderComment() {
    let input =
      """
      // Top comment
      import Bimport
      1️⃣import Aimport

      let A = 123
      """

    let expected =
      """
      import Aimport
      // Top comment
      import Bimport

      let A = 123
      """

    assertFormatting(
      OrderedImports.self,
      input: input,
      expected: expected,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }

  func testMultipleCodeBlocksPerLine() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import A;import Z;1️⃣import D;import C;
        foo();bar();baz();quxxe();
        """,
      expected: """
        import A;
        import C;
        import D;
        import Z;

        foo();bar();baz();quxxe();
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }

  func testMultipleCodeBlocksWithImportsPerLine() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import A;import Z;1️⃣import D;import C;foo();bar();baz();quxxe();
        """,
      expected: """
        import A;
        import C;
        import D;
        import Z;

        foo();bar();baz();quxxe();
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }

  func testDisableOrderedImports() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import C
        1️⃣import B
        // swift-format-ignore: OrderedImports
        import A
        let a = 123
        2️⃣import func Darwin.C.isatty

        // swift-format-ignore
        import a
        """,
      expected: """
        import B
        import C

        // swift-format-ignore: OrderedImports
        import A

        import func Darwin.C.isatty

        let a = 123

        // swift-format-ignore
        import a
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically"),
        FindingSpec("2️⃣", message: "place imports at the top of the file"),
      ]
    )
  }

  func testDisableOrderedImportsMovingComments() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import C  // Trailing comment about C
        1️⃣import B
        // Comment about ignored A
        // swift-format-ignore: OrderedImports
        import A  // trailing comment about ignored A
        // Comment about Z
        import Z
        2️⃣import D
        // swift-format-ignore
        // Comment about testable testA
        @testable import testA
        @testable import testZ  // trailing comment about testZ
        3️⃣@testable import testC
        // swift-format-ignore
        @testable import testB
        // Comment about Bar
        import enum Bar

        let a = 2
        """,
      expected: """
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically"),
        FindingSpec("2️⃣", message: "sort import statements lexicographically"),
        FindingSpec("3️⃣", message: "sort import statements lexicographically"),
      ]
    )
  }

  func testEmptyFile() {
    assertFormatting(
      OrderedImports.self,
      input: "",
      expected: "",
      findings: []
    )

    assertFormatting(
      OrderedImports.self,
      input: "// test",
      expected: "// test",
      findings: []
    )
  }

  func testImportsContainingNewlines() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import
          zeta
        1️⃣import Zeta
        import
          Alpha
        import Beta
        """,
      expected: """
        import
          Alpha
        import Beta
        import Zeta
        import
          zeta
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }

  func testRemovesDuplicateImports() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import CoreLocation
        import UIKit
        1️⃣import CoreLocation
        import ZeeFramework
        bar()
        """,
      expected: """
        import CoreLocation
        import UIKit
        import ZeeFramework

        bar()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove this duplicate import")
      ]
    )
  }

  func testDuplicateCommentedImports() {
    // Verify that we diagnose redundant imports if they have comments, but don't remove them.
    assertFormatting(
      OrderedImports.self,
      input: """
        import AppKit
        // CoreLocation is necessary to get location stuff.
        import CoreLocation  // This import must stay.
        // UIKit does UI Stuff?
        import UIKit
        // This is the second CoreLocation import.
        1️⃣import CoreLocation  // The 2nd CL import has a comment here too.
        // Comment about ZeeFramework.
        import ZeeFramework
        import foo
        // Second comment about ZeeFramework.
        2️⃣import ZeeFramework  // This one has a trailing comment too.
        foo()
        """,
      expected: """
        import AppKit
        // CoreLocation is necessary to get location stuff.
        import CoreLocation  // This import must stay.
        // This is the second CoreLocation import.
        import CoreLocation  // The 2nd CL import has a comment here too.
        // UIKit does UI Stuff?
        import UIKit
        // Comment about ZeeFramework.
        // Second comment about ZeeFramework.
        import ZeeFramework  // This one has a trailing comment too.
        import foo

        foo()
        """,
      findings: [
        // Even though this import is technically also not sorted, that won't matter if the import
        // is removed so there should only be a warning to remove it.
        FindingSpec("1️⃣", message: "remove this duplicate import"),
        FindingSpec("2️⃣", message: "remove this duplicate import"),
      ]
    )
  }

  func testDuplicateIgnoredImports() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import AppKit
        // swift-format-ignore
        import CoreLocation
        // Second CoreLocation import here.
        import CoreLocation
        // Comment about ZeeFramework.
        import ZeeFramework
        // swift-format-ignore
        import ZeeFramework  // trailing comment
        foo()
        """,
      expected: """
        import AppKit

        // swift-format-ignore
        import CoreLocation

        // Second CoreLocation import here.
        import CoreLocation
        // Comment about ZeeFramework.
        import ZeeFramework

        // swift-format-ignore
        import ZeeFramework  // trailing comment

        foo()
        """,
      findings: []
    )
  }

  func testDuplicateAttributedImports() {
    assertFormatting(
      OrderedImports.self,
      input: """
        // exported import of bar
        @_exported import bar
        @_implementationOnly import bar
        import bar
        import foo
        // second import of foo
        1️⃣import foo

        // imports an enum
        import enum Darwin.D.isatty
        // this is a dup
        2️⃣import enum Darwin.D.isatty

        @testable import foo

        baz()
        """,
      expected: """
        // exported import of bar
        @_exported import bar
        @_implementationOnly import bar
        import bar
        // second import of foo
        import foo

        // imports an enum
        // this is a dup
        import enum Darwin.D.isatty

        @testable import foo

        baz()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove this duplicate import"),
        FindingSpec("2️⃣", message: "remove this duplicate import"),
      ]
    )
  }

  func testConditionalImports() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import Zebras
        1️⃣import Apples
        #if canImport(Darwin)
          import Darwin
        #elseif canImport(Glibc)
          import Glibc
        #endif
        2️⃣import Aardvarks

        foo()
        bar()
        baz()
        """,
      expected: """
        import Aardvarks
        import Apples
        import Zebras

        #if canImport(Darwin)
          import Darwin
        #elseif canImport(Glibc)
          import Glibc
        #endif

        foo()
        bar()
        baz()
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically"),
        FindingSpec("2️⃣", message: "place imports at the top of the file"),
      ]
    )
  }

  func testIgnoredConditionalImports() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import Zebras
        1️⃣import Apples
        #if canImport(Darwin)
          import Darwin
        #elseif canImport(Glibc)
          import Glibc
        #endif
        // swift-format-ignore
        import Aardvarks

        foo()
        bar()
        baz()
        """,
      expected: """
        import Apples
        import Zebras

        #if canImport(Darwin)
          import Darwin
        #elseif canImport(Glibc)
          import Glibc
        #endif
        // swift-format-ignore
        import Aardvarks

        foo()
        bar()
        baz()
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }

  func testTrailingCommentsOnTopLevelCodeItems() {
    assertFormatting(
      OrderedImports.self,
      input: """
        import Zebras
        1️⃣import Apples
        #if canImport(Darwin)
          import Darwin
        #elseif canImport(Glibc)
          import Glibc
        #endif  // canImport(Darwin)

        foo()  // calls the foo
        bar()  // calls the bar
        """,
      expected: """
        import Apples
        import Zebras

        #if canImport(Darwin)
          import Darwin
        #elseif canImport(Glibc)
          import Glibc
        #endif  // canImport(Darwin)

        foo()  // calls the foo
        bar()  // calls the bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )
  }
}
