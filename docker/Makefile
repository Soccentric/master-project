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

.PHONY: install-docker
install-docker:
	@if ! command -v docker > /dev/null 2>&1; then \
		echo "Docker not installed. Installing..."; \
		sudo apt-get update && sudo apt-get install -y docker.io; \
		sudo systemctl start docker; \
		sudo systemctl enable docker; \
		sudo usermod -aG docker $(USER); \
		echo "Docker installed and user added to docker group. Please log out and log back in for group changes to take effect."; \
	else \
		echo "Docker is already installed."; \
	fi
