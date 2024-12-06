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

#if os(Windows)
import WinSDK
#endif

extension URL {
  /// Returns a `Bool` to indicate if the given `URL` leads to the root of a filesystem.
  /// A non-filesystem type `URL` will always return false.
  @_spi(Testing) public var isRoot: Bool {
    guard isFileURL else { return false }

    #if os(macOS)
    return self.path == NSOpenStepRootDirectory()
    #endif

    #if compiler(>=6.1)
    #if os(Windows)
    return self.path.withCString(encodedAs: UTF16.self, PathCchIsRoot)
    #elseif os(Linux)
    return self.path == "/"
    #endif
    #else

    #if os(Windows)
    // This is needed as the fixes from #844 aren't in the Swift 6.0 toolchain.
    // https://github.com/swiftlang/swift-format/issues/844
    var pathComponents = self.pathComponents
    if pathComponents.first == "/" {
      // Canonicalize `/C:/` to `C:/`.
      pathComponents = Array(pathComponents.dropFirst())
    }
    return pathComponents.count <= 1
    #elseif os(Linux)
    // On Linux, we may end up with an string for the path due to https://github.com/swiftlang/swift-foundation/issues/980
    // This is needed as the fixes from #980 aren't in the Swift 6.0 toolchain.
    return self.path == "/" || self.path == ""
    #endif

    #endif
  }
}
