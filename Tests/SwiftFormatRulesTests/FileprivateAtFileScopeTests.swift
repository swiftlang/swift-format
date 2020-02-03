import SwiftFormatRules

final class FileprivateAtFileScopeTests: DiagnosingTestCase {
  func testFileScopeDecls() {
    XCTAssertFormatting(
      FileprivateAtFileScope.self,
      input: """
        private class Foo {}
        private struct Foo {}
        private enum Foo {}
        private protocol Foo {}
        private typealias Foo = Bar
        private extension Foo {}
        private func foo() {}
        private var foo: Bar
        """,
      expected: """
        fileprivate class Foo {}
        fileprivate struct Foo {}
        fileprivate enum Foo {}
        fileprivate protocol Foo {}
        fileprivate typealias Foo = Bar
        fileprivate extension Foo {}
        fileprivate func foo() {}
        fileprivate var foo: Bar
        """)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
  }

  func testNonFileScopeDeclsAreNotChanged() {
    XCTAssertFormatting(
      FileprivateAtFileScope.self,
      input: """
        enum Namespace {
          private class Foo {}
          private struct Foo {}
          private enum Foo {}
          private typealias Foo = Bar
          private static func foo() {}
          private static var foo: Bar
        }
        """,
      expected: """
        enum Namespace {
          private class Foo {}
          private struct Foo {}
          private enum Foo {}
          private typealias Foo = Bar
          private static func foo() {}
          private static var foo: Bar
        }
        """)
    XCTAssertNotDiagnosed(.replacePrivateWithFileprivate)
  }

  func testFileScopeDeclsInsideConditionals() {
    XCTAssertFormatting(
      FileprivateAtFileScope.self,
      input: """
        #if FOO
          private class Foo {}
          private struct Foo {}
          private enum Foo {}
          private protocol Foo {}
          private typealias Foo = Bar
          private extension Foo {}
          private func foo() {}
          private var foo: Bar
        #elseif BAR
          private class Foo {}
          private struct Foo {}
          private enum Foo {}
          private protocol Foo {}
          private typealias Foo = Bar
          private extension Foo {}
          private func foo() {}
          private var foo: Bar
        #else
          private class Foo {}
          private struct Foo {}
          private enum Foo {}
          private protocol Foo {}
          private typealias Foo = Bar
          private extension Foo {}
          private func foo() {}
          private var foo: Bar
        #endif
        """,
      expected: """
        #if FOO
          fileprivate class Foo {}
          fileprivate struct Foo {}
          fileprivate enum Foo {}
          fileprivate protocol Foo {}
          fileprivate typealias Foo = Bar
          fileprivate extension Foo {}
          fileprivate func foo() {}
          fileprivate var foo: Bar
        #elseif BAR
          fileprivate class Foo {}
          fileprivate struct Foo {}
          fileprivate enum Foo {}
          fileprivate protocol Foo {}
          fileprivate typealias Foo = Bar
          fileprivate extension Foo {}
          fileprivate func foo() {}
          fileprivate var foo: Bar
        #else
          fileprivate class Foo {}
          fileprivate struct Foo {}
          fileprivate enum Foo {}
          fileprivate protocol Foo {}
          fileprivate typealias Foo = Bar
          fileprivate extension Foo {}
          fileprivate func foo() {}
          fileprivate var foo: Bar
        #endif
        """)
  }

  func testFileScopeDeclsInsideNestedConditionals() {
    XCTAssertFormatting(
      FileprivateAtFileScope.self,
      input: """
        #if FOO
          #if BAR
            private class Foo {}
            private struct Foo {}
            private enum Foo {}
            private protocol Foo {}
            private typealias Foo = Bar
            private extension Foo {}
            private func foo() {}
            private var foo: Bar
          #endif
        #endif
        """,
      expected: """
        #if FOO
          #if BAR
            fileprivate class Foo {}
            fileprivate struct Foo {}
            fileprivate enum Foo {}
            fileprivate protocol Foo {}
            fileprivate typealias Foo = Bar
            fileprivate extension Foo {}
            fileprivate func foo() {}
            fileprivate var foo: Bar
          #endif
        #endif
        """)
  }

  func testLeadingTriviaIsPreserved() {
    XCTAssertFormatting(
      FileprivateAtFileScope.self,
      input: """
        /// Some doc comment
        private class Foo {}

        @objc /* comment */ private class Bar {}
        """,
      expected: """
        /// Some doc comment
        fileprivate class Foo {}

        @objc /* comment */ fileprivate class Bar {}
        """)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
  }

  func testModifierDetailIsPreserved() {
    XCTAssertFormatting(
      FileprivateAtFileScope.self,
      input: """
        public private(set) var foo: Int
        """,
      expected: """
        public fileprivate(set) var foo: Int
        """)
    XCTAssertDiagnosed(.replacePrivateWithFileprivate)
  }
}
