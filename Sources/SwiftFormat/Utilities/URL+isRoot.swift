//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

extension URL {
  @_spi(Testing) public var isRoot: Bool {
    #if os(Windows)
    // FIXME: We should call into Windows' native check to check if this path is a root once https://github.com/swiftlang/swift-foundation/issues/976 is fixed.
    // https://github.com/swiftlang/swift-format/issues/844
    var pathComponents = self.pathComponents
    if pathComponents.first == "/" {
      // Canonicalize `/C:/` to `C:/`.
      pathComponents = Array(pathComponents.dropFirst())
    }
    return pathComponents.count <= 1
    #else
    // On Linux, we may end up with an string for the path due to https://github.com/swiftlang/swift-foundation/issues/980
    // TODO: Remove the check for "" once https://github.com/swiftlang/swift-foundation/issues/980 is fixed.
    return self.path == "/" || self.path == ""
    #endif
  }
}
