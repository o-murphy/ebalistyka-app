#!/bin/bash

set -e

echo "--- Apdate package list... ---"
sudo apt-get update -q

echo "--- Setup build dependencies (Linux)... ---"
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev \
  libclang-dev \
  fuse \
  libfuse2 \
  zsync

echo "--- Setup complete success! ---"