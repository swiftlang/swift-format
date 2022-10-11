//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore
import SwiftSyntax

/// A visitor that determines if the target source file imports `XCTest`.
private class ImportsXCTestVisitor: SyntaxVisitor {
  private let context: Context

  init(context: Context) {
    self.context = context
    super.init(viewMode: .sourceAccurate)
  }

  override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
    // If we already know whether or not `XCTest` is imported, don't bother doing anything else.
    guard context.importsXCTest == .notDetermined else { return .skipChildren }

    // If the first import path component is the `XCTest` module, record that fact. Checking in this
    // way lets us catch `import XCTest` but also specific decl imports like
    // `import class XCTest.XCTestCase`, if someone wants to do that.
    if node.path.first!.name.tokenKind == .identifier("XCTest") {
      context.importsXCTest = .importsXCTest
    }

    return .skipChildren
  }

  override func visitPost(_ node: SourceFileSyntax) {
    // If we visited the entire source file and didn't find an `XCTest` import, record that fact.
    if context.importsXCTest == .notDetermined {
      context.importsXCTest = .doesNotImportXCTest
    }
  }
}

/// Sets the appropriate value of the `importsXCTest` field in the context, which approximates
/// whether the file contains test code or not.
///
/// This setter will only run the visitor if another rule hasn't already called this function to
/// determine if the source file imports `XCTest`.
///
/// - Parameters:
///   - context: The context information of the target source file.
///   - sourceFile: The file to be visited.
public func setImportsXCTest(context: Context, sourceFile: SourceFileSyntax) {
  guard context.importsXCTest == .notDetermined else { return }
  let visitor = ImportsXCTestVisitor(context: context)
  visitor.walk(sourceFile)
}
