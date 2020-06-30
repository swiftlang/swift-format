#!/bin/bash

BUILD_PATH=.build/release
LIB_PATH=$BUILD_PATH/lib
BIN_PATH=$BUILD_PATH/bin/swift-format
SWIFT_PATH=$(xcrun --find swift)

swift build --configuration release --disable-sandbox
rm -rf $LIB_PATH
rm -rf $BIN_PATH
mkdir -p $LIB_PATH
mkdir -p $BUILD_PATH/bin
cp .build/release/swift-format $BIN_PATH
cp "$(dirname $SWIFT_PATH)/../lib/swift/macosx/lib_InternalSwiftSyntaxParser.dylib" $LIB_PATH/lib_InternalSwiftSyntaxParser.dylib
install_name_tool -add_rpath @executable_path/../lib $BIN_PATH
tar -C $BUILD_PATH -czf swift-format.tar.gz bin lib
mv swift-format.tar.gz .build
