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

/// Types that conform to this protocol can be used as the category of a finding.
///
/// A finding's category should have a human-readable string representation (by overriding the
/// `description` property from the inherited `CustomStringConvertible` conformance). This is meant
/// to be displayed as part of the diagnostic message when the finding is presented to the user.
/// For example, the category `Indentation` in the message `[Indentation] Indent by 2 spaces`.
public protocol FindingCategorizing: CustomStringConvertible {

}
