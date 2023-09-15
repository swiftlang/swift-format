//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormatConfiguration

/// Loads formatter configurations, caching them in memory so that multiple operations in the same
/// directory do not repeatedly hit the file system.
struct ConfigurationLoader {
  /// The cache of previously loaded configurations.
  private var cache = [String: Configuration]()

  /// Returns the configuration found by searching in the directory (and ancestor directories)
  /// containing the given `.swift` source file.
  ///
  /// If no configuration file was found during the search, this method returns nil.
  ///
  /// - Throws: If a configuration file was found but an error occurred loading it.
  mutating func configuration(forSwiftFileAt url: URL) throws -> Configuration? {
    guard let configurationFileURL = Configuration.url(forConfigurationFileApplyingTo: url)
    else {
      return nil
    }
    return try configuration(at: configurationFileURL)
  }

  /// Returns the configuration associated with the configuration file at the given URL.
  ///
  /// - Throws: If an error occurred loading the configuration.
  mutating func configuration(at url: URL) throws -> Configuration {
    let cacheKey = url.absoluteURL.standardized.path
    if let cachedConfiguration = cache[cacheKey] {
      return cachedConfiguration
    }

    let configuration = try Configuration(contentsOf: url)
    cache[cacheKey] = configuration
    return configuration
  }
}
