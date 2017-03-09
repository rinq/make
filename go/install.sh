#!/usr/bin/env bash
set -e

MANIFEST="Makefile.in build.sh runtime.go"
mkdir -p artifacts/make
cd artifacts/make

echo "Downloading Makefile dependencies"
for FILE in $MANIFEST; do
    curl -L -o "${FILE}" "https://rinq.github.io.make/go/${FILE}"
done

echo "Detecting current OS and architecture"
go run runtime.go | tee -a Makefile.in
