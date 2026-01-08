#!/bin/bash
DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y graphviz cmake dpkg-dev build-essential debhelper devscripts dh-make gnupg dput fakeroot gpg-agent
