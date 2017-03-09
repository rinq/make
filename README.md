# Rinq Makefiles

This repository contains common Makefile configurations used by Rinq projects.
projects.

The contents is not intended to be used by third-parties and may change at any
time without notice.

## Go

A `Makefile` for Go, Glide and Docker.

Usage:

```Makefile
-include artifacts/make/Makefile.in

artifacts/make/Makefile.in:
	bash <(curl -s https://rinq.github.io/make/go/install)
```
