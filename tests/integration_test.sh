#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GREEN="\033[0;32m"
NC="\033[0m"
source "$DIR/test_utils.sh"
set -e 

cd "$DIR"/../
BUILD_DIR=./build/integration_test

expect_file "$BUILD_DIR"/CMakeDependencyDiagrams/cmake.dot.png
expect_file "$BUILD_DIR"/CMakeDependencyDiagrams/index.html 
expect_file "$BUILD_DIR"/CMakeDependencyDiagrams/listOfTargetFileDependencyDiagrams.js 


expect_string_in_file some_interface_lib.dependers "$BUILD_DIR"/CMakeDependencyDiagrams/listOfTargetFileDependencyDiagrams.js 

echo -e "$GREEN""PASSED: Integration test$NC"
