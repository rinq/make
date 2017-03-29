################################################################################
# Rinq Makefile for Docker
################################################################################

# Pre-requisites for building the Docker image. This would typically include
# anything you want to COPY or ADD to the image.
DOCKER_REQ ?=

ifndef DOCKER_REPO
$(error "DOCKER_REPO must be defined in the project's Makefile.")
endif

ifdef TRAVIS_TAG
DOCKER_TAG ?= $(TRAVIS_TAG)
else
DOCKER_TAG ?= dev
endif

################################################################################
# Commands (Phony Targets)
################################################################################

.PHONY: docker
docker: artifacts/logs/docker/$(DOCKER_TAG)

.PHONY: docker-push
docker-push: docker
	docker push $(DOCKER_REPO):$(DOCKER_TAG)

ifdef TRAVIS_TAG
	$(eval PARTS := $(subst ., ,$(DOCKER_TAG)))
	$(eval MAJOR := $(word 1,$(PARTS)))
	$(eval MINOR := $(word 2,$(PARTS)))
	$(eval PATCH := $(word 3,$(PARTS)))

	docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REPO):latest
	docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REPO):$(MAJOR)
	docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REPO):$(MAJOR).$(MINOR)

	docker push $(DOCKER_REPO):latest
	docker push $(DOCKER_REPO):$(MAJOR)
	docker push $(DOCKER_REPO):$(MAJOR).$(MINOR)
endif

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
