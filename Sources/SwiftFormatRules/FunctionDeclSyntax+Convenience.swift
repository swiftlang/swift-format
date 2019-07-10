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

import SwiftSyntax

extension FunctionDeclSyntax {
  /// Constructs a name for a function that includes parameter labels, i.e. `foo(_:bar:)`.
  var fullDeclName: String {
    let params = signature.input.parameterList.map { param in
      "\(param.firstName?.text ?? "_"):"
    }
    return "\(identifier.text)(\(params.joined()))"
  }
}
