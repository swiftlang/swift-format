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
import SwiftFormat

/// Loads formatter configurations, caching them in memory so that multiple operations in the same
/// directory do not repeatedly hit the file system.
actor ConfigurationLoader {
  /// Keeps track of the state of configurations in the cache.
  private enum CacheEntry {
    /// The configuration has been fully loaded.
    case ready(Configuration)

    /// The configuration is in the process of being loaded.
    case loading(Task<Configuration, Error>)
  }

  /// The cache of previously loaded configurations.
  private var cache = [String: CacheEntry]()

  /// Returns the configuration found by searching in the directory (and ancestor directories)
  /// containing the given `.swift` source file.
  ///
  /// If no configuration file was found during the search, this method returns nil.
  ///
  /// - Throws: If a configuration file was found but an error occurred loading it.
  func configuration(forSwiftFileAt url: URL) async throws -> Configuration? {
    guard let configurationFileURL = Configuration.url(forConfigurationFileApplyingTo: url)
    else {
      return nil
    }
    return try await configuration(at: configurationFileURL)
  }

  /// Returns the configuration associated with the configuration file at the given URL.
  ///
  /// - Throws: If an error occurred loading the configuration.
  func configuration(at url: URL) async throws -> Configuration {
    let cacheKey = url.absoluteURL.standardized.path

    if let cached = cache[cacheKey] {
      switch cached {
      case .ready(let configuration):
        return configuration
      case .loading(let task):
        return try await task.value
      }
    }

    let task = Task {
      try Configuration(contentsOf: url)
    }
    cache[cacheKey] = .loading(task)

    do {
      let configuration = try await task.value
      cache[cacheKey] = .ready(configuration)
      return configuration
    } catch {
      cache[cacheKey] = nil
      throw error
    }
  }
}
