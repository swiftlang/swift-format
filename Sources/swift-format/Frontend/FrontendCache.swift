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

typealias FrontendName = String
typealias FrontendCache = [FrontendName: Cache]

struct Cache: Codable {
  typealias Key = String
  typealias Value = Date

  private var modifiedDateByFilepath: [Key: Value]

  subscript(filepath: Key) -> Value? {
    get {
      return modifiedDateByFilepath[filepath]
    }
    set {
      modifiedDateByFilepath[filepath] = newValue
    }
  }

  init() {
    self.modifiedDateByFilepath = [:]
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.modifiedDateByFilepath = try container.decode([Key:Value].self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(modifiedDateByFilepath)
  }
}
