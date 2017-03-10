################################################################################
# Rinq Makefile for Go
################################################################################

# This file is generated automatically, do not edit it.
#
# To override the variables in this section, define them in the project's
# Makefile before including this file.

# Build matrix configuration.
#
# MATRIX_OS is a whitespace separated set of operating systems.
# MATRIX_ARCH is a whitespace separated set of CPU architectures.
#
# The build-matrix is constructed from all possible permutations of MATRIX_OS and
# MATRIX_ARCH. The default is to build only for the current OS and architecture.
-include artifacts/make/runtime.in
MATRIX_OS   ?= $(GOOS)
MATRIX_ARCH ?= $(GOARCH)

# Disable CGO by default.
# See https://golang.org/cmd/cgo
CGO_ENABLED ?= 0

# Arguments passed to "go build" for debug / release builds.
DEBUG_ARGS   ?= -v
RELEASE_ARGS ?= -v -ldflags "-s -w"

# The REQ and USE variables are used as pre-requisites for all targets that
# execute the project's Go source, including tests.
#
# They can be used to specify additional build dependencies other than the .go
# source files, such as HTML assets, etc.
#
# REQ is used a "normal" pre-requisite, whereas USE is an "order-only"
# pre-requisite.
#
# See https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html
REQ ?=
USE ?=

# Docker build configuration.
# DOCKER_REPO must be defined in the project's Makefile.

ifdef TRAVIS_TAG
DOCKER_TAG ?= $(TRAVIS_TAG)
else
DOCKER_TAG ?= dev
endif

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

################################################################################
# Commands (Phony Targets)
################################################################################

# Run all tests.
.PHONY: test
.DEFAULT_GOAL ?= test
test: vendor $(REQ) | $(USE)
	go test ./src/...

# Run all tests with race detection enabled.
.PHONY: test-race
test-race: vendor $(REQ) | $(USE)
	go test -race ./src/...

# Build debug executables for the current OS and architecture.
.PHONY: build
build: $(addprefix artifacts/build/debug/$(GOOS)/$(GOARCH)/,$(_BINS))

# Build debug executables for all OS and architecture combinations.
.PHONY: debug
.SECONDARY: $(addprefix artifacts/build/debug/,$(_STEMS))
debug: $(addprefix artifacts/build/debug/,$(_STEMS))

# Build release executables for all OS and architecture combinations.
.PHONY: release
.SECONDARY: $(addprefix artifacts/build/release/,$(_STEMS))
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
lint: artifacts/touch/go-lint

# Perform pre-commit checks.
.PHONY: prepare
prepare: lint test artifacts/touch/go-errcheck artifacts/touch/travis-lint

ifdef DOCKER_REPO

.PHONY: docker
docker: artifacts/touch/docker/$(DOCKER_TAG)

.PHONY: docker-clean
docker-clean:
	rm -f artifacts/touch/docker/$(DOCKER_TAG)
	-docker image rm $(DOCKER_REPO):$(DOCKER_TAG)

.PHONY: docker-push
docker-push: docker
	docker push $(DOCKER_REPO):$(DOCKER_TAG)

else # ifdef DOCKER_REPO

.PHONY: docker
docker:
	@echo "DOCKER_REPO not defined in Makefile"
	@false

endif # ifdef DOCKER_REPO

# Run the CI build.
#
# TODO: no need for the merged coverage file under travis CI, as codecov.io
.PHONY: ci
ci: lint test-race $(_COV)

################################################################################
# File Targets
################################################################################

GLIDE := $(GOPATH)/bin/glide
$(GLIDE):
	go get -u github.com/Masterminds/glide

GOCOVMERGE := $(GOPATH)/bin/gocovmerge
$(GOCOVMERGE):
	go get -u github.com/wadey/gocovmerge

MISSPELL := $(GOPATH)/bin/misspell
$(MISSPELL):
	go get github.com/client9/misspell/cmd/misspell

ERRCHECK := $(GOPATH)/bin/errcheck
$(ERRCHECK):
	go get -u github.com/kisielk/errcheck

GOMETALINTER := $(GOPATH)/bin/gometalinter.v1
$(GOMETALINTER):
	go get -u gopkg.in/alecthomas/gometalinter.v1
	$(GOMETALINTER) --install 2>/dev/null

vendor: glide.lock | $(GLIDE)
	$(GLIDE) install
	@touch vendor

glide.lock: glide.yaml | $(GLIDE)
	$(GLIDE) update
	@touch vendor

artifacts/build/%: vendor $(REQ) $(_SRC) | $(USE)
	$(eval PARTS := $(subst /, ,$*))
	$(eval BUILD := $(word 1,$(PARTS)))
	$(eval OS    := $(word 2,$(PARTS)))
	$(eval ARCH  := $(word 3,$(PARTS)))
	$(eval BIN   := $(word 4,$(PARTS)))
	$(eval ARGS  := $(if $(findstring debug,$(BUILD)),$(DEBUG_ARGS),$(RELEASE_ARGS)))

	CGO_ENABLED=$(CGO_ENABLED) GOOS="$(OS)" GOARCH="$(ARCH)" go build $(ARGS) -o "$@" "./src/cmd/$(BIN)"

artifacts/tests/coverage/index.html: artifacts/tests/coverage/coverage.cov
	go tool cover -html="$<" -o "$@"

artifacts/tests/coverage/coverage.cov: $(_COV) | $(GOCOVMERGE)
	@mkdir -p $(@D)
	$(GOCOVMERGE) $^ > "$@"

.SECONDEXPANSION:
%/package.cov: vendor $(REQ) $$(subst artifacts/tests/coverage/,,$$(@D))/*.go | $(USE)
	$(eval PKG := $(subst artifacts/tests/coverage/,,$*))
	@mkdir -p "$(@D)"
	@touch "$@" # no file is written if there are no tests
	-go test "$(PKG)" -covermode=count -coverprofile="$@"

artifacts/touch/go-lint: vendor $(_SRC) $(REQ) | $(MISSPELL) $(GOMETALINTER) $(USE)
	go vet ./src/...
	! go fmt ./src/... | grep ^

	$(MISSPELL) -w -error -locale US ./src

	$(GOMETALINTER) --vendor --disable-all --deadline=30s \
		--enable=vet \
		--enable=vetshadow \
		--enable=ineffassign \
		--enable=deadcode \
		--enable=gosimple \
		--enable=gofmt \
		./src/...

	-$(GOMETALINTER) --vendor --disable-all --deadline=30s --cyclo-over=15 \
		--enable=golint \
		--enable=goconst \
		--enable=gocyclo \
		./src/...

	@mkdir -p "$(@D)"
	@touch "$@"

artifacts/touch/go-errcheck: vendor $(_SRC) $(REQ) | $(ERRCHECK) $(USE)
	-$(ERRCHECK) ./src/...
	@mkdir -p "$(@D)"
	@touch "$@"

artifacts/touch/travis-lint: $(wildcard .travis.yml)
	! [ -f "$<" ] || travis lint
	@mkdir -p "$(@D)"
	@touch "$@"

.SECONDARY: $(addprefix artifacts/build/release/linux/amd64/,$(_BINS))
artifacts/touch/docker/%: Dockerfile $(addprefix artifacts/build/release/linux/amd64/,$(_BINS))
	docker build --compress -t $(DOCKER_REPO):$* .
	@mkdir -p "$(@D)"
	@touch "$@"

artifacts/make/runtime.in:
	echo "GOOS ?= $(shell go env GOOS)" > "$@"
	echo "GOARCH ?= $(shell go env GOARCH)" >> "$@"
