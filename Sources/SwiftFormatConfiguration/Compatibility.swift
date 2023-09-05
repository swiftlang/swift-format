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

// Make these symbols that used to live in `SwiftFormatConfiguration` available when that module is
// imported.
// TODO: Remove this after the 509 release.
@_exported import struct SwiftFormat.Configuration
@_exported import struct SwiftFormat.FileScopedDeclarationPrivacyConfiguration
@_exported import struct SwiftFormat.NoAssignmentInExpressionsConfiguration
@_exported import enum SwiftFormat.Indent
