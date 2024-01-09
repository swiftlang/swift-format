#[[
This source file is part of the swift-format open source project

Copyright (c) 2024 Apple Inc. and the swift-format project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(_SwiftFormatInstructionCounter STATIC
  src/InstructionsExecuted.c)
target_include_directories(_SwiftFormatInstructionCounter PUBLIC
  include)
