################################################################################
# Rinq Makefile for Go
################################################################################

# This file is generated automatically, do not edit it.
#
# To override the variables in this section, define them in the project's
# Makefile before including this file. Additional build dependencies can be
# specified by adding the _req and _use targets to the project's Makefile.
#
# The _req and _use targets are used as pre-requisites for all targets that
# execute the project's Go source, including tests.
#
# They can be used to specify additional build dependencies other than the .go
# source files, such as HTML assets, etc.
#
# _req is used a "normal" pre-requisite, whereas "_use" is an order-only
# pre-requisite.
#
# See https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html
.PHONY: _req _use

# Build matrix configuration.
#
# MATRIX_OS is a whitespace separated set of operating systems.
# MATRIX_ARCH is a whitespace separated set of CPU architectures.
#
# The build-matrix is constructed from all possible permutations of MATRIX_OS and
# MATRIX_ARCH. The default is to build only for the current OS and architecture.
-include artifacts/make/runtime.mk
MATRIX_OS   ?= $(_OS)
MATRIX_ARCH ?= $(_ARCH)

# Disable CGO by default.
# See https://golang.org/cmd/cgo
CGO_ENABLED ?= 0

# Arguments passed to "go build" for debug / release builds.
DEBUG_ARGS   ?= -v
RELEASE_ARGS ?= -v -ldflags "-s -w"

################################################################################
# Commands (Phony Targets)
################################################################################

# Run all tests.
.PHONY: test
.DEFAULT_GOAL ?= test
test: vendor _req | _use
	go test ./src/...

# Run all tests with race detection enabled.
.PHONY: test-race
test-race:
	go test -race ./src/...

# Build debug executables for the current OS and architecture.
.PHONY: build
build: $(addprefix artifacts/build/debug/$(_OS)/$(_ARCH)/,$(_BINS))

# Build debug executables for all OS and architecture combinations.
.PHONY: debug
debug: $(addprefix artifacts/build/debug/,$(_STEMS))

# Build release executables for all OS and architecture combinations.
.PHONY: release
release: $(addprefix artifacts/build/release/,$(_STEMS))

# Remove all files that match the patterns .gitignore.
.PHONY: clean
clean:
	@git check-ignore ./* | xargs -t -n1 rm -rf

# Remove files that match the patterns .gitignore, excluding the vendor folder.
.PHONY: clean-nv
clean-nv:
	@git check-ignore ./* | grep -v ^./vendor | xargs -t -n1 rm -rf

# Generate an HTML code coverage report.
.PHONY: coverage
coverage: artifacts/tests/coverage/index.html

# Generate an HTML code coverage report and open it in the browser.
# TODO: This command only works on OSX.
.PHONY: coverage-open
coverage-open: artifacts/tests/coverage/index.html
	open "$<"

# Perform code linting, syntax formatting, etc.
.PHONY: lint
lint: vendor
	go vet ./src/...
	! go fmt ./src/... | grep ^

# Perform pre-commit checks.
.PHONY: prepare
prepare: lint test
	[ ! -f .travis.yml ] || travis lint

# Run the CI build.
#
# TODO: no need for the merged coverage file under travis CI, as codecov.io
.PHONY: ci
ci: lint test-race $(_COV)

################################################################################
# File Targets
################################################################################

vendor: glide.lock | $(GLIDE)
	$(GLIDE) install
	@touch vendor

glide.lock: glide.yaml | $(GLIDE)
	$(GLIDE) update
	@touch vendor

artifacts/build/debug/%: vendor _req $(_SRC) | _use
	CGO_ENABLED=$(CGO_ENABLED) \
		GOOS="$(notdir $(dir $(@D)))" \
		GOARCH="$(notdir $(@D))" \
		go build $(DEBUG_ARGS) -o "$@" "./src/cmd/$(notdir $@)"

artifacts/build/release/%: vendor _req $(_SRC) | _use
	CGO_ENABLED=$(CGO_ENABLED) \
		GOOS="$(notdir $(dir $(@D)))" \
		GOARCH="$(notdir $(@D))" \
		go build $(RELEASE_ARGS) -o "$@" "./src/cmd/$(notdir $@)"

artifacts/tests/coverage/index.html: artifacts/tests/coverage/coverage.cov
	go tool cover -html="$<" -o "$@"

artifacts/tests/coverage/coverage.cov: $(_COV) | $(GOCOVMERGE)
	@mkdir -p $(@D)
	$(GOCOVMERGE) $^ > "$@"

.SECONDEXPANSION:
%/package.cov: vendor _req $$(subst artifacts/tests/coverage/,,$$(@D))/*.go | _use
	$(eval PKG := $(subst artifacts/tests/coverage/,,$*))
	@mkdir -p "$(@D)"
	@touch "$@" # no file is written if there are no tests
	-go test "$(PKG)" -covermode=count -coverprofile="$@"

artifacts/make/runtime.mk:
	echo "GOOS ?= $(shell go env GOOS)" > "$@"
	echo "GOARCH ?= $(shell go env GOARCH)" >> "$@"

################################################################################
# Third-party dependencies.
################################################################################

GLIDE := $(GOPATH)/bin/glide
$(GLIDE):
	go get -u github.com/Masterminds/glide

GOCOVMERGE := $(GOPATH)/bin/gocovmerge
$(GOCOVMERGE):
	go get -u github.com/wadey/gocovmerge

################################################################################
# Internal variables
################################################################################

# _MATRIX contains all permutations of MATRIX_ARCH and MATRIX_OS
_MATRIX ?= $(foreach OS,$(MATRIX_OS),$(foreach ARCH,$(MATRIX_ARCH),$(OS)/$(ARCH)))

# _SRC contains the paths to all Go source files.
_SRC ?= $(shell find ./src -name *.go)

# _PKGS contains the paths to all Go packages under ./src
_PKGS ?= $(sort $(dir $(_SRC)))

# _BINS contains the names of binaries (directories under ./src/cmd)
_BINS ?= $(notdir $(shell find src/cmd -mindepth 1 -maxdepth 1 -type d 2>/dev/null))

# _STEMS contains the binary names for each entry in the MATRIX (e.g. darwin/amd64/<bin>)
_STEMS ?= $(foreach B,$(_MATRIX),$(foreach BIN,$(_BINS),$(B)/$(BIN)))

# _COV contains the paths to a "package.cov" file for each package.
_COV ?= $(foreach P,$(_PKGS),artifacts/tests/coverage/$(P)package.cov)
