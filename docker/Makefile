################################################################################
# Rinq Makefile for Docker
################################################################################

# Pre-requisites for building the Docker image. This would typically include
# anything you want to COPY or ADD to the image.
DOCKER_REQ ?=

# The Docker image tag to build (and optionally publish).
# This defaults to "dev" which is the tag used for local testing.
# Never push the "dev" tag to the registry.
ifdef TRAVIS_TAG
DOCKER_TAG ?= $(TRAVIS_TAG)
else
DOCKER_TAG ?= dev
endif

ifndef DOCKER_REPO
$(error "DOCKER_REPO must be defined in the project's Makefile.")
endif

################################################################################
# Commands (Phony Targets)
################################################################################

.PHONY: docker
docker: artifacts/logs/docker/$(DOCKER_TAG)

.PHONY: docker-push
ifeq ($(DOCKER_TAG),dev)
	$(error "Don't push the :dev tag to the registry!")
else
	docker push $(DOCKER_REPO):$(DOCKER_TAG)
endif # DOCKER_TAG == dev

.PHONY: docker-clean
docker-clean::
	rm -f artifacts/logs/docker/$(DOCKER_TAG)
	-docker image rm $(DOCKER_REPO):$(DOCKER_TAG)

.PHONY: clean-all
clean-all:: docker-clean

################################################################################
# File Targets
################################################################################

.SECONDARY: $(DOCKER_REQ)
artifacts/logs/docker/%: Dockerfile $(DOCKER_REQ)
	@mkdir -p "$(@D)"
	docker build -t $(DOCKER_REPO):$* . | tee "$@"
