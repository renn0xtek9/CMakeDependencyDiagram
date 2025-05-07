#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/test_utils.sh"
set -e 
cd output
sudo apt remove -y cmake-dependency-diagram
sudo apt install -y ./cmake-dependency-diagram_1.0.0_all.deb
cd ..
cd tests 
BUILD_DIR=./../build/integration_test
mkdir -p "$BUILD_DIR"
cmake -S integration_test -B "$BUILD_DIR" --graphviz="$BUILD_DIR"cmake.dot
cmake --build "$BUILD_DIR" --target cmake-dependency-diagrams


expect_file "$BUILD_DIR"/CMakeDependencyDiagrams/cmake.dot.png
expect_file "$BUILD_DIR"/CMakeDependencyDiagrams/index.html 
expect_file "$BUILD_DIR"/CMakeDependencyDiagrams/listOfTargetFileDependencyDiagrams.js 

echo "PASSED: Integration test"
