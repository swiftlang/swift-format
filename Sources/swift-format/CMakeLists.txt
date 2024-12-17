#[[
This source file is part of the swift-format open source project

Copyright (c) 2024 Apple Inc. and the swift-format project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_executable(swift-format
  PrintVersion.swift
  SwiftFormatCommand.swift
  VersionOptions.swift
  Frontend/ConfigurationLoader.swift
  Frontend/FormatFrontend.swift
  Frontend/Frontend.swift
  Frontend/LintFrontend.swift
  Subcommands/DumpConfiguration.swift
  Subcommands/Format.swift
  Subcommands/Lint.swift
  Subcommands/LintFormatOptions.swift
  Subcommands/PerformanceMeasurement.swift
  Utilities/Diagnostic.swift
  Utilities/DiagnosticsEngine.swift
  Utilities/FileHandleTextOutputStream.swift
  Utilities/FormatError.swift
  Utilities/StderrDiagnosticPrinter.swift
  Utilities/TTY.swift)
target_link_libraries(swift-format PRIVATE
  _SwiftFormatInstructionCounter
  ArgumentParser
  SwiftFormat
  SwiftParser
  SwiftSyntax)

set_target_properties(swift-format PROPERTIES
  INSTALL_RPATH "$<$<PLATFORM_ID:Darwin>:@executable_path/../lib/swift/macosx;@executable_path/../lib/swift/host;@executable_path/../lib/swift/host/compiler>")

_install_target(swift-format)
