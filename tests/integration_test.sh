#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/test_utils.sh"
set -e 
cd output
sudo apt remove -y cmake-dependency-diagram

# Ensure the package is owned by _apt user. See https://www.reddit.com/r/linux4noobs/comments/ux6cwx/installation_errors_on_deb_files_apt/
# It enables us skipping some warning that do not return 0.
sudo chown _apt ./cmake-dependency-diagram_1.0.0_all.deb 
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
