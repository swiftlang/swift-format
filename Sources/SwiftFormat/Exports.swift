//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore

// The `SwiftFormatCore` module isn't meant for public use, but these types need to be since they
// are also part of the public `SwiftFormat` API. Use public typealiases to "re-export" them for
// now.

public typealias Finding = SwiftFormatCore.Finding
public typealias FindingCategorizing = SwiftFormatCore.FindingCategorizing
