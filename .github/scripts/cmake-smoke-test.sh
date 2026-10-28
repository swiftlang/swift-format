#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift.org open source project
##
## Copyright (c) 2026 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
## See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
##
##===----------------------------------------------------------------------===##

# Build using CMake for validation purposes.
#
# Any arguments passed to this script are forwarded to CMake as extra
# configuration arguments (e.g. -DCMAKE_Swift_COMPILER=...).

set -euo pipefail

# The package to build. In CI this is the checkout the build command runs in;
# locally it defaults to the current directory.
source_dir="${GITHUB_WORKSPACE:-$PWD}"
build_dir="${BUILD_DIR:-"$source_dir/.cmake-smoke-test"}"

mkdir -p "$build_dir"

cmake -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$(command -v ninja)" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_Swift_FLAGS="-module-cache-path $build_dir/module-cache" \
    "$@" \
    -S "$source_dir" -B "$build_dir"

cmake --build "$build_dir"
