#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GREEN="\033[0;32m"
NC="\033[0m"

PLATFORM="$1" # e.g., "ubuntu-22" or "ubuntu-24"

source "$DIR/test_utils.sh"
set -e 

cd "$DIR"/../
BUILD_DIR=./build/integration_test/"$PLATFORM"

expect_file "$BUILD_DIR"/CMakeDependencyDiagram/cmake.dot.png
expect_file "$BUILD_DIR"/CMakeDependencyDiagram/index.html 
expect_file "$BUILD_DIR"/CMakeDependencyDiagram/listOfTargetFileDependencyDiagram.js 


expect_string_in_file some_interface_lib.dependers "$BUILD_DIR"/CMakeDependencyDiagram/listOfTargetFileDependencyDiagram.js 

echo -e "$GREEN""PASSED: Integration test$NC"
