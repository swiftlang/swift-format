#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift.org open source project
##
## Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
## See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
##
##===----------------------------------------------------------------------===##

# SYNOPSIS
#   format-diff.sh FILE [OPTION]...
#
# DESCRIPTION
#   Runs the formatter and displays a side-by-side diff of the original file
#   and the formatted results. The script will use `colordiff` for the output
#   if it is present; otherwise, regular `diff` will be used.
#
#   The first argument to this script must be the `.swift` source file to be
#   formatted. Any remaining arguments after that will be passed directly to
#   `swift-format`.

set -euo pipefail

SRCFILE="$1" ; shift

# Use `colordiff` if it's present; otherwise, fall back to `diff`.
if which colordiff >/dev/null ; then
  DIFF="$(which colordiff)"
else
  DIFF="$(which diff)"
fi

# Make sure the formatter is built in debug mode so we can reference the
# executable easily.
swift build --product swift-format

# Run a side-by-side diff with the original source file on the left and the
# formatted output on the right.
"$DIFF" -y -W 210 "$SRCFILE" <(.build/debug/swift-format "$@" "$SRCFILE")
