#[[
This source file is part of the swift-format open source project

Copyright (c) 2024 Apple Inc. and the swift-format project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

set(SWIFT_FORMAT_EXPORTS_FILE
  ${CMAKE_CURRENT_BINARY_DIR}/SwiftFormatExports.cmake)

configure_file(SwiftFormatConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/SwiftFormatConfig.cmake)

get_property(SWIFT_FORMAT_EXPORTS GLOBAL PROPERTY SWIFT_FORMAT_EXPORTS)
export(TARGETS ${SWIFT_FORMAT_EXPORTS}
  NAMESPACE SwiftFormat::
  FILE ${SWIFT_FORMAT_EXPORTS_FILE}
  EXPORT_LINK_INTERFACE_LIBRARIES)
