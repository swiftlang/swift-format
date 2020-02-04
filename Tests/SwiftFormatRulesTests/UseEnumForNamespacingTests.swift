import SwiftFormatRules

final class UseEnumForNamespacingTests: LintOrFormatRuleTestCase {
  func testNonEnumsUsedAsNamespaces() {
    XCTAssertFormatting(
      UseEnumForNamespacing.self,
      input: """
             struct A {
               static func foo() {}
               private init() {}
             }
             struct B {
               var x: Int = 3
               static func foo() {}
               private init() {}
             }
             class C {
               static func foo() {}
             }
             public final class D {
               static func bar()
             }
             final class E {
               static let a = 123
             }
             struct Structure {
               #if canImport(AppKit)
                   var native: NSSomething
               #elseif canImport(UIKit)
                   var native: UISomething
               #endif
             }
             struct Structure {
               #if canImport(AppKit)
                   static var native: NSSomething
               #elseif canImport(UIKit)
                   static var native: UISomething
               #endif
             }
             struct Structure {
               #if canImport(AppKit)
                   var native: NSSomething
               #elseif canImport(UIKit)
                   static var native: UISomething
               #endif
             }
             struct Structure {
               #if canImport(AppKit)
                   static var native: NSSomething
               #else
                   static var native: UISomething
               #endif
             }
             struct Structure {
               #if canImport(AppKit)
                 #if swift(>=4.0)
                   static var native: NSSomething
                 #else
                   static var deprecated_native: NSSomething
                 #endif
               #else
                   #if swift(>=4.0)
                     static var native: UISomething
                   #else
                     static var deprecated_native: UISomething
                   #endif
               #endif
             }
             struct Structure {
               #if canImport(AppKit)
                 #if swift(>=4.0)
                   static var native: NSSomething
                 #else
                   static var deprecated_native: NSSomething
                 #endif
               #else
                   #if swift(>=4.0)
                     static var native: UISomething
                   #else
                     var deprecated_native: UISomething
                   #endif
               #endif
             }
             """,
      expected: """
                enum A {
                  static func foo() {}
                }
                struct B {
                  var x: Int = 3
                  static func foo() {}
                  private init() {}
                }
                class C {
                  static func foo() {}
                }
                public final class D {
                  static func bar()
                }
                final class E {
                  static let a = 123
                }
                struct Structure {
                  #if canImport(AppKit)
                      var native: NSSomething
                  #elseif canImport(UIKit)
                      var native: UISomething
                  #endif
                }
                enum Structure {
                  #if canImport(AppKit)
                      static var native: NSSomething
                  #elseif canImport(UIKit)
                      static var native: UISomething
                  #endif
                }
                struct Structure {
                  #if canImport(AppKit)
                      var native: NSSomething
                  #elseif canImport(UIKit)
                      static var native: UISomething
                  #endif
                }
                enum Structure {
                  #if canImport(AppKit)
                      static var native: NSSomething
                  #else
                      static var native: UISomething
                  #endif
                }
                enum Structure {
                  #if canImport(AppKit)
                    #if swift(>=4.0)
                      static var native: NSSomething
                    #else
                      static var deprecated_native: NSSomething
                    #endif
                  #else
                      #if swift(>=4.0)
                        static var native: UISomething
                      #else
                        static var deprecated_native: UISomething
                      #endif
                  #endif
                }
                struct Structure {
                  #if canImport(AppKit)
                    #if swift(>=4.0)
                      static var native: NSSomething
                    #else
                      static var deprecated_native: NSSomething
                    #endif
                  #else
                      #if swift(>=4.0)
                        static var native: UISomething
                      #else
                        var deprecated_native: UISomething
                      #endif
                  #endif
                }
                """)
  }

  public func testNestedEnumsForNameSpaces() {
     XCTAssertFormatting(
       UseEnumForNamespacing.self,
       input: """
              struct A {
                static func fooA() {}
                struct B {
                  static func fooB() {}
                }
              }
              struct C {
                func fooC() {}
                struct D {
                  static func fooB() {}
                }
              }
              struct E {
                static func fooE() {}
                struct F {
                  func fooF() {}
                }
              }
              struct G {
                func fooG() {}
                #if useH
                struct H {
                  static func fooH() {}
                }
                #endif
              }
              """,
       expected: """
                 enum A {
                   static func fooA() {}
                   enum B {
                     static func fooB() {}
                   }
                 }
                 struct C {
                   func fooC() {}
                   enum D {
                     static func fooB() {}
                   }
                 }
                 enum E {
                   static func fooE() {}
                   struct F {
                     func fooF() {}
                   }
                 }
                 struct G {
                   func fooG() {}
                   #if useH
                   enum H {
                     static func fooH() {}
                   }
                   #endif
                 }
                 """)
   }
}
