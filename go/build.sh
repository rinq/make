#!/usr/bin/env bash
set -e
set -x

# $1 is the path to the executable to produce, which includes path atoms for the
# OS and architecture: e.g. artifacts/build/debug/darwin/amd64/cmdname
export GOOS="$(basename $(dirname $(dirname $1)))"
export GOARCH="$(basename $(dirname $1))"
go build "${@:2}" -o "$1" "./src/cmd/$(basename $1)"
