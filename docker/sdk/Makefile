# Makefile for building SDK Docker images
# This builds a Docker image with the Yocto SDK installed

# Default values (can be overridden)
BASE_IMAGE ?= master-builder:latest
MACHINE_FAMILY ?= unknown
SDK_FILE ?= 
IMAGE_NAME := sdk-build-$(MACHINE_FAMILY)
TAG ?= latest

.PHONY: build
build:
	@if [ -z "$(SDK_FILE)" ]; then \
		echo "Error: SDK_FILE must be specified"; \
		echo "Usage: make build SDK_FILE=<path-to-sdk.sh> MACHINE_FAMILY=<family>"; \
		exit 1; \
	fi; \
	if [ ! -f "$(SDK_FILE)" ]; then \
		echo "Error: SDK file not found: $(SDK_FILE)"; \
		exit 1; \
	fi; \
	@echo "Building SDK Docker image..."; \
	echo "  Base Image:      $(BASE_IMAGE)"; \
	echo "  Machine Family:  $(MACHINE_FAMILY)"; \
	echo "  SDK File:        $(SDK_FILE)"; \
	echo "  Image Name:      $(IMAGE_NAME):$(TAG)"; \
	mkdir -p tmp && \
	cp "$(SDK_FILE)" tmp/sdk-installer.sh && \
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		-t $(IMAGE_NAME):$(TAG) \
		. && \
	rm -rf tmp

.PHONY: run
run:
	@docker run -it --rm $(IMAGE_NAME):$(TAG)

.PHONY: clean
clean:
	@docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	@rm -f *.sh
	@rm -rf tmp

.PHONY: help
help:
	@echo "SDK Docker Image Builder"
	@echo ""
	@echo "Targets:"
	@echo "  build          - Build SDK Docker image"
	@echo "  run            - Run SDK Docker image interactively"
	@echo "  clean          - Remove SDK Docker image"
	@echo ""
	@echo "Variables:"
	@echo "  SDK_FILE       - Path to SDK installer script (required)"
	@echo "  MACHINE_FAMILY - Machine family name (required)"
	@echo "  BASE_IMAGE     - Base Docker image (default: master-builder:latest)"
	@echo "  TAG            - Image tag (default: latest)"
	@echo ""
	@echo "Example:"
	@echo "  make build SDK_FILE=/path/to/sdk.sh MACHINE_FAMILY=raspberry-pi"
