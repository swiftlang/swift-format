#!/usr/bin/env bash

set -ex

SWIFT_SYNTAX_TAG="$1"
SWIFT_FORMAT_VERSION="$2"

if [[ -z "$SWIFT_SYNTAX_TAG" || -z "$SWIFT_FORMAT_VERSION" ]]; then
  echo "Update the Package manifest to reference a specific version of swift-syntax and embed the given version in the swift-format --version command"
  echo "Usage create-release-commits.sh <SWIFT_SYNTAX_TAG> <SWIFT_FORMAT_VERSION>"
  echo "  SWIFT_SYNTAX_TAG:     The tag of swift-syntax to depend on"
  echo "  SWIFT_FORMAT_VERSION: The version of swift-format that is about to be released"
  exit 1
fi

# Without this, we can't perform git operations in GitHub actions.
git config --global --add safe.directory "$(realpath .)"

git config --local user.name 'swift-ci'
git config --local user.email 'swift-ci@users.noreply.github.com'

sed -E -i "s#branch: \"(main|release/[0-9]+\.[0-9]+)\"#from: \"$SWIFT_SYNTAX_TAG\"#" Package.swift
git add Package.swift
git commit -m "Change swift-syntax dependency to $SWIFT_SYNTAX_TAG"

sed -E -i "s#print\(\".*\"\)#print\(\"$SWIFT_FORMAT_VERSION\"\)#" Sources/swift-format/PrintVersion.swift
git add Sources/swift-format/PrintVersion.swift
git commit -m "Change version to $SWIFT_FORMAT_VERSION"
