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

/// The enablement of a lint/format rule based on the presence or absence of comment directives in
/// the source file.
public enum RuleState {

  /// There is no explicit information in the source file about whether the rule should be enabled
  /// or disabled at the requested location, so the configuration default should be used.
  case `default`

  /// The rule is explicitly disabled at the requested location.
  case disabled
}
