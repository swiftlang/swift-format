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
import SwiftSyntaxParser

class CacheProcessor {
  private let fileIterator: FileIterator
  private let diagnosticEngine: DiagnosticEngine
  private let fileManager: FileManager
  private let frontendName: String

  init(
    fileIterator: FileIterator,
    diagnosticEngine: DiagnosticEngine,
    fileManager: FileManager,
    frontendName: String
  ) {
    self.fileIterator = fileIterator
    self.diagnosticEngine = diagnosticEngine
    self.fileManager = fileManager
    self.frontendName = frontendName
  }

  func process(_ work: ([String]) -> Void) {
    let cacheDirURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("swift-format", isDirectory: true)
    let cacheFileURL = cacheDirURL.appendingPathComponent("cache.json")
    var caches: FrontendCache
    if fileManager.fileExists(atPath: cacheFileURL.path) {
      let cacheData: Data
      do {
        cacheData = try Data(contentsOf: cacheFileURL)
      } catch {
        diagnosticEngine.diagnose(Diagnostic.Message.init(
          .warning,
          "We won't use cache due to cannot read cache data in '\(cacheFileURL)': \(error.localizedDescription)")
        )
        work(Array(fileIterator))
        return
      }

      do {
        caches = try JSONDecoder().decode(FrontendCache.self, from: cacheData)
      } catch {
        diagnosticEngine.diagnose(Diagnostic.Message.init(
          .warning,
          "We won't use cache due to failed to decode cache data in '\(cacheFileURL)': \(error.localizedDescription)")
        )
        work(Array(fileIterator))
        return
      }
    } else {
      caches = .init()
    }

    let cache = caches[frontendName] ?? Cache()

    work(filePathsToProcess(cache: cache))

    updateCacheFile(caches: caches, cacheFileURL: cacheFileURL)
  }

  private func filePathsToProcess(cache: Cache) -> [String] {
    let lock = NSLock()

    var filePathsToProcess: [String] = []

    let dispatchGroup = DispatchGroup()
    let filePaths = Array(fileIterator)
    for filePath in filePaths {
      dispatchGroup.enter()
      DispatchQueue.global().async(execute: { [weak self] in
        defer { dispatchGroup.leave() }
        guard let self = self else { return }
        guard let attrs = try? self.fileManager.attributesOfItem(atPath: filePath) else {
          return
        }
        guard let modificationDate = attrs[.modificationDate] as? Date else {
          return
        }
        guard let cachedModDate = cache[filePath] else {
          lock.lock()
          filePathsToProcess.append(filePath)
          lock.unlock()
          return
        }
        if modificationDate > cachedModDate {
          lock.lock()
          filePathsToProcess.append(filePath)
          lock.unlock()
        }
      })
    }
    dispatchGroup.wait()

    return filePathsToProcess
  }

  private func updateCacheFile(caches: FrontendCache, cacheFileURL: URL) {
    let lock = NSLock()
    var caches = caches
    var cache = caches[self.frontendName] ?? Cache()

    let dispatchGroup = DispatchGroup()
    let filePaths = Array(fileIterator)
    for filePath in filePaths {
      dispatchGroup.enter()
      DispatchQueue.global().async(execute: { [weak self] in
        defer { dispatchGroup.leave() }
        guard let self = self else { return }
        guard let attrs = try? self.fileManager.attributesOfItem(atPath: filePath) else {
          return
        }
        guard let modificationDate = attrs[.modificationDate] as? Date else {
          return
        }
        lock.lock()
        cache[filePath] = modificationDate
        lock.unlock()
      })
    }
    dispatchGroup.wait()

    caches[frontendName] = cache

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    let data: Data
    do {
      data = try encoder.encode(caches)
    } catch {
      diagnosticEngine.diagnose(Diagnostic.Message.init(
        .warning,
        "Failed to encode cache data: \(error.localizedDescription)")
      )
      return
    }

    let cacheDirURL = cacheFileURL.deletingLastPathComponent()
    do {
      try fileManager.createDirectory(at: cacheDirURL, withIntermediateDirectories: true)
    } catch {
      diagnosticEngine.diagnose(Diagnostic.Message.init(
        .warning,
        "Failed to create cache directory '\(cacheDirURL)': \(error.localizedDescription)")
      )
    }

    fileManager.createFile(atPath: cacheFileURL.path, contents: nil)

    do {
      try data.write(to: cacheFileURL)
    } catch {
      diagnosticEngine.diagnose(Diagnostic.Message.init(
        .warning,
        "Failed to update cache file '\(cacheFileURL)': \(error.localizedDescription)")
      )
    }
  }
}
