#!/bin/bash 
set -euxo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

VERSION="1.0.0"
BUILD_DIR="./build/ppa_upload"
PACKAGE_NAME="cmake-dependency-diagram_${VERSION}"
mkdir -p "$BUILD_DIR/$PACKAGE_NAME"
cp -r packaging/ubuntu-22/debian "$BUILD_DIR/$PACKAGE_NAME"
cd "$BUILD_DIR/$PACKAGE_NAME"
debuild -S -sa -k04C9FB399050560B20F3DE85C86F45E902C8D9B7 # Find the correct key ID with gpg --list-keys

cd "$DIR/$BUILD_DIR"
ls -la
dput ppa:maxime-haselbauer/cmake-dependency-diagram "$PACKAGE_NAME"_source.changes
