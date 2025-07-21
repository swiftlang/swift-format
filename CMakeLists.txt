#[[
This source file is part of the swift-format open source project

Copyright (c) 2024 Apple Inc. and the swift-format project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

cmake_minimum_required(VERSION 3.19.0)

if(POLICY CMP0077)
  cmake_policy(SET CMP0077 NEW)
endif()
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()

project(SwiftFormat
  LANGUAGES C Swift)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)
set(CMAKE_Swift_COMPILE_OPTIONS_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

include(FetchContent)
include(GNUInstallDirs)
include(SwiftSupport)

find_package(Foundation CONFIG)

set(_SF_VENDOR_DEPENDENCIES)

set(BUILD_EXAMPLES NO)
set(BUILD_TESTING NO)

find_package(ArgumentParser CONFIG)
if(NOT ArgumentParser_FOUND)
  FetchContent_Declare(ArgumentParser
    GIT_REPOSITORY https://github.com/apple/swift-argument-parser
    GIT_TAG 1.2.3)
  list(APPEND _SF_VENDOR_DEPENDENCIES ArgumentParser)
endif()

find_package(cmark-gfm CONFIG)
if(NOT cmark-gfm_FOUND)
  FetchContent_Declare(cmark-gfm
    GIT_REPOSITORY https://github.com/swiftlang/swift-cmark
    GIT_TAG gfm)
  list(APPEND _SF_VENDOR_DEPENDENCIES cmark-gfm)
endif()

find_package(SwiftMarkdown CONFIG)
if(NOT SwiftMarkdown_FOUND)
  # TODO(compnerd) we need a latest version for now as we need the CMake support
  # which is untagged.
  FetchContent_Declare(Markdown
    GIT_REPOSITORY https://github.com/swiftlang/swift-markdown
    GIT_TAG main)
  list(APPEND _SF_VENDOR_DEPENDENCIES Markdown)
endif()

find_package(SwiftSyntax CONFIG)
if(NOT SwiftSyntax_FOUND)
  FetchContent_Declare(Syntax
    GIT_REPOSITORY https://github.com/swiftlang/swift-syntax
    GIT_TAG main)
  list(APPEND _SF_VENDOR_DEPENDENCIES Syntax)
endif()

if(_SF_VENDOR_DEPENDENCIES)
  FetchContent_MakeAvailable(${_SF_VENDOR_DEPENDENCIES})

  if(NOT TARGET SwiftMarkdown::Markdown)
    add_library(SwiftMarkdown::Markdown ALIAS Markdown)
  endif()

  if(NOT TARGET SwiftSyntax::SwiftSyntax)
    add_library(SwiftSyntax::SwiftSyntax ALIAS SwiftSyntax)
    add_library(SwiftSyntax::SwiftSyntaxBuilder ALIAS SwiftSyntaxBuilder)
    add_library(SwiftSyntax::SwiftOperators ALIAS SwiftOperators)
    add_library(SwiftSyntax::SwiftParser ALIAS SwiftParser)
    add_library(SwiftSyntax::SwiftParserDiagnostics ALIAS SwiftParserDiagnostics)
  endif()
endif()

add_subdirectory(Sources)
