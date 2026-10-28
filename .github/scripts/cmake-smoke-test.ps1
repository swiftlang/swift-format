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

param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

# The package to build. In CI this is the checkout the build command runs in;
# locally it defaults to the current directory.
$SourceDir = if ($env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE } else { (Get-Location).Path }
$BuildDir = if ($env:BUILD_DIR) { $env:BUILD_DIR } else { Join-Path $SourceDir ".cmake-smoke-test" }

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

cmake -G Ninja `
    "-DCMAKE_MAKE_PROGRAM=$((Get-Command ninja).Path)" `
    "-DCMAKE_BUILD_TYPE=Debug" `
    "-DCMAKE_Swift_FLAGS=-module-cache-path $BuildDir/module-cache" `
    @ExtraArgs `
    -S $SourceDir -B $BuildDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

cmake --build $BuildDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
