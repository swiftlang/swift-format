//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
@_spi(Internal) import SwiftFormat

// FIXME: This needn't be MainActor because we never actually access it concurrently.
//        It can be made nonisolated if decoupled from the Sendable Frontend.
/// Provides formatter configurations for given `.swift` source files, configuration files or configuration strings.
@MainActor
final class ConfigurationProvider {
  /// Loads formatter configuration files and caches them in memory.
  private var configurationLoader: ConfigurationLoader

  /// The diagnostic engine to which warnings and errors will be emitted.
  private let diagnosticsEngine: DiagnosticsEngine

  /// Creates a new instance with the given options.
  ///
  /// - Parameter diagnosticsEngine: The diagnostic engine to which warnings and errors will be emitted.
  nonisolated init(diagnosticsEngine: DiagnosticsEngine) {
    self.diagnosticsEngine = diagnosticsEngine
    self.configurationLoader = ConfigurationLoader()
  }

  /// Checks if all the rules in the given configuration are supported by the registry.
  ///
  /// If there are any rules that are not supported, they are emitted as a warning.
  private func checkForUnrecognizedRules(in configuration: Configuration) {
    // If any rules in the decoded configuration are not supported by the registry,
    // emit them into the diagnosticsEngine as warnings.
    // That way they will be printed out, but we'll continue execution on the valid rules.

    for (key, _) in configuration.rules {
      if RuleRegistry.rules.keys.contains(key) {
        continue
      }
      diagnosticsEngine.emitWarning("Configuration contains an unrecognized rule: \(key)", location: nil)
    }
  }

  /// Returns the configuration that applies to the given `.swift` source file, when an explicit
  /// configuration path is also perhaps provided.
  ///
  /// This method also checks for unrecognized rules within the configuration.
  ///
  /// - Parameters:
  ///   - pathOrString: A string containing either the path to a configuration file that will be
  ///     loaded, JSON configuration data directly, or `nil` to try to infer it from
  ///     `swiftFileURL`.
  ///   - swiftFileURL: The path to a `.swift` file, which will be used to infer the path to the
  ///     configuration file if `configurationFilePath` is nil.
  ///
  /// - Returns: If successful, the returned configuration is the one loaded from `pathOrString` if
  ///   it was provided, or by searching in paths inferred by `swiftFileURL` if one exists, or the
  ///   default configuration otherwise. If an error occurred when reading the configuration, a
  ///   diagnostic is emitted and `nil` is returned. If neither `pathOrString` nor `swiftFileURL`
  ///   were provided, a default `Configuration()` will be returned.
  func provide(
    forConfigPathOrString pathOrString: String?,
    orForSwiftFileAt swiftFileURL: URL?
  ) -> Configuration? {
    if let pathOrString = pathOrString {
      // If an explicit configuration file path was given, try to load it and fail if it cannot be
      // loaded. (Do not try to fall back to a path inferred from the source file path.)
      let configurationFileURL = URL(fileURLWithPath: pathOrString)
      do {
        let configuration = try configurationLoader.configuration(at: configurationFileURL)
        self.checkForUnrecognizedRules(in: configuration)
        return configuration
      } catch {
        // If we failed to load this from the path, try interpreting the string as configuration
        // data itself because the user might have written something like `--configuration '{...}'`,
        let data = pathOrString.data(using: .utf8)!
        if let configuration = try? Configuration(data: data) {
          return configuration
        }

        // Fail if the configuration flag was neither a valid file path nor valid configuration
        // data.
        diagnosticsEngine.emitError("Unable to read configuration: \(error.localizedDescription)")
        return nil
      }
    }

    // If no explicit configuration file path was given but a `.swift` source file path was given,
    // then try to load the configuration by inferring it based on the source file path.
    if let swiftFileURL = swiftFileURL {
      do {
        if let configuration = try configurationLoader.configuration(forPath: swiftFileURL) {
          self.checkForUnrecognizedRules(in: configuration)
          return configuration
        }
        // Fall through to the default return at the end of the function.
      } catch {
        diagnosticsEngine.emitError(
          "Unable to read configuration for \(swiftFileURL.relativePath): \(error.localizedDescription)"
        )
        return nil
      }
    } else {
      // If reading from stdin and no explicit configuration file was given,
      // walk up the file tree from the cwd to find a config.

      let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      // Definitely a Swift file. Definitely not a directory. Shhhhhh.
      do {
        if let configuration = try configurationLoader.configuration(forPath: cwd) {
          self.checkForUnrecognizedRules(in: configuration)
          return configuration
        }
      } catch {
        diagnosticsEngine.emitError(
          "Unable to read configuration for \(cwd.relativePath): \(error.localizedDescription)"
        )
        return nil
      }
    }

    // An explicit configuration has not been given, and one cannot be found.
    // Return the default configuration.
    return Configuration()
  }
}
