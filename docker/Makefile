# Makefile for building the Yocto Kas Docker image

IMAGE_NAME := master-builder
TAG := latest

.PHONY: build
build:
	docker build -t $(IMAGE_NAME):$(TAG) .

.PHONY: run
run:
	docker run -it --rm $(IMAGE_NAME):$(TAG)

.PHONY: clean
clean:
	docker rmi $(IMAGE_NAME):$(TAG)
