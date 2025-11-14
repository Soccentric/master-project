# ==============================================================================
# Professional Makefile for KAS-based Board Building System
# Version: 2.0.0
# ==============================================================================

# Variables
SHELL := /bin/bash
.ONESHELL:  # Use one shell for multi-line commands
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null || pwd)
BUILD_DIR := build
BOARDS_DIR := boards
SOURCES_DIR := sources
ARTIFACTS_DIR := artifacts
DOCKER_IMAGE := master-builder:latest
WORKSPACE_MOUNT := /workspace
VERSION := 2.0.0
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Prerequisites check
REQUIRED_TOOLS := docker git
define CHECK_TOOLS
	@for tool in $(REQUIRED_TOOLS); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo -e "$(COLOR_YELLOW)Error: $$tool is required but not installed$(COLOR_RESET)"; \
			exit 1; \
		fi; \
	done
endef

# Docker run base command
DOCKER_RUN := docker run --rm --network host \
	-v $(GIT_ROOT):$(WORKSPACE_MOUNT) \
	-w $(WORKSPACE_MOUNT) \
	--user $(shell id -u):$(shell id -g) \
	$(if $(HTTP_PROXY),-e HTTP_PROXY=$(HTTP_PROXY)) \
	$(if $(HTTPS_PROXY),-e HTTPS_PROXY=$(HTTPS_PROXY)) \
	$(if $(FTP_PROXY),-e FTP_PROXY=$(FTP_PROXY)) \
	$(if $(NO_PROXY),-e NO_PROXY=$(NO_PROXY)) \
	$(if $(http_proxy),-e http_proxy=$(http_proxy)) \
	$(if $(https_proxy),-e https_proxy=$(https_proxy)) \
	$(if $(ftp_proxy),-e ftp_proxy=$(ftp_proxy)) \
	$(if $(no_proxy),-e no_proxy=$(no_proxy))

# Color output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m
COLOR_RED := \033[31m

# ==============================================================================
# Default target
# ==============================================================================
.DEFAULT_GOAL := help

.PHONY: all
all: help

# ==============================================================================
# Prerequisites
# ==============================================================================
.PHONY: prerequisites
prerequisites:
	$(CHECK_TOOLS)
	@echo -e "$(COLOR_GREEN)✓ All prerequisites satisfied$(COLOR_RESET)"

# ==============================================================================
# Build targets
# ==============================================================================
.PHONY: build
build: prerequisites docker-build
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make build <board-name>"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	yml_file=$$(find $(BOARDS_DIR) -name "$$board.yml" | head -1); \
	if [ -z "$$yml_file" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Board '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	board_build_dir="$(BUILD_DIR)/$$board"; \
	board_sources_dir="$(SOURCES_DIR)/$$board"; \
	start_time=$$(date +%s); \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting build for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Creating build directory structure: $$board_build_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
	echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_sources_dir"; \
	echo -e "$(COLOR_GREEN)Starting KAS build...$(COLOR_RESET)"; \
	if $(DOCKER_RUN) \
		-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
		$(DOCKER_IMAGE) \
		kas build $(WORKSPACE_MOUNT)/$$yml_file; then \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ Build completed successfully for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "Build artifacts located in: $$board_build_dir"; \
		echo -e "Sources located in: $$board_sources_dir"; \
	else \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_RED)✗ Build failed for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
		echo -e "  • Check build logs: $$board_build_dir/tmp/log/"; \
		echo -e "  • Common issues:"; \
		echo -e "    - Network connectivity for source downloads"; \
		echo -e "    - Insufficient disk space"; \
		echo -e "    - Invalid machine/distro configuration"; \
		echo -e "    - Missing dependencies in Docker image"; \
		echo -e "  • Try: make clean $$board && make build $$board"; \
		exit 1; \
	fi

.PHONY: dry-run
dry-run: prerequisites docker-build
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make dry-run <board-name>"; \
		echo "       make dry-run-all"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	yml_file=$$(find $(BOARDS_DIR) -name "$$board.yml" | head -1); \
	if [ -z "$$yml_file" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Board '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	board_build_dir="$(BUILD_DIR)/$$board"; \
	board_sources_dir="$(SOURCES_DIR)/$$board"; \
	start_time=$$(date +%s); \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting dry-run for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Validating configuration for $$board...$(COLOR_RESET)"; \
	if command -v python3 >/dev/null 2>&1; then \
		if python3 -c "import yaml; yaml.safe_load(open('$$yml_file'))" 2>/dev/null; then \
			echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ YAML syntax valid$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Machine: $$(grep '^machine:' $$yml_file | awk '{print $$2}')$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Distro: $$(grep '^distro:' $$yml_file | awk '{print $$2}')$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Target: $$(grep '^target:' $$yml_file | awk '{print $$2}')$(COLOR_RESET)"; \
		else \
			echo -e "$(COLOR_YELLOW)✗ Invalid YAML syntax$(COLOR_RESET)"; \
			exit 1; \
		fi; \
	else \
		echo -e "$(COLOR_GREEN)✓ Configuration file exists$(COLOR_RESET)"; \
	fi; \
	echo ""; \
	echo -e "$(COLOR_GREEN)Creating build directories...$(COLOR_RESET)"; \
	mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
	mkdir -p "$$board_sources_dir"; \
	echo -e "$(COLOR_GREEN)Fetching sources (this may take a while)...$(COLOR_RESET)"; \
	if $(DOCKER_RUN) \
		-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
		$(DOCKER_IMAGE) \
		kas checkout $(WORKSPACE_MOUNT)/$$yml_file; then \
		echo ""; \
		echo -e "$(COLOR_GREEN)Parsing recipes (dry-run mode)...$(COLOR_RESET)"; \
		if $(DOCKER_RUN) \
			-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
			$(DOCKER_IMAGE) \
			kas shell $(WORKSPACE_MOUNT)/$$yml_file -c 'bitbake -n -p'; then \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo ""; \
			echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ Dry-run completed successfully for $$board$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Sources fetched to: $$board_sources_dir$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Build directory: $$board_build_dir$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Configuration validated and ready to build$(COLOR_RESET)"; \
		else \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_YELLOW)✗ Recipe parsing failed for $$board$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
			echo -e "  • BitBake parsing error - check recipe syntax"; \
			echo -e "  • Check logs: $$board_build_dir/tmp/log/"; \
			echo -e "  • Verify machine/distro/target in $$yml_file"; \
			echo -e "  • Try: make clean $$board && make dry-run $$board"; \
			exit 1; \
		fi; \
	else \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_YELLOW)✗ Source checkout failed for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
		echo -e "  • Network issues or invalid repository URLs"; \
		echo -e "  • Check repository access and branch names in $$yml_file"; \
		echo -e "  • Insufficient disk space for sources"; \
		echo -e "  • Try: make clean $$board && make dry-run $$board"; \
		exit 1; \
	fi

.PHONY: dry-run-all
dry-run-all:
	@start_time=$$(date +%s); \
	echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Validating all board configurations (YAML syntax check)...$(COLOR_RESET)"; \
	echo ""; \
	failed_boards=""; \
	passed_boards=""; \
	total=0; \
	vendor_counts=""; \
	for yml_file in $$(find $(BOARDS_DIR) -name "*.yml" | sort); do \
		board_name=$$(basename $$yml_file .yml); \
		vendor=$$(echo $$yml_file | sed 's|$(BOARDS_DIR)/||' | cut -d'/' -f1); \
		total=$$((total + 1)); \
		if command -v python3 >/dev/null 2>&1; then \
			if python3 -c "import yaml; yaml.safe_load(open('$$yml_file'))" 2>/dev/null; then \
				machine=$$(python3 -c "import yaml; data=yaml.safe_load(open('$$yml_file')); print(data.get('machine', ''))" 2>/dev/null || echo ""); \
				distro=$$(python3 -c "import yaml; data=yaml.safe_load(open('$$yml_file')); print(data.get('distro', ''))" 2>/dev/null || echo ""); \
				target=$$(python3 -c "import yaml; data=yaml.safe_load(open('$$yml_file')); t=data.get('target', []); print(t[0] if isinstance(t, list) and t else t if t else '')" 2>/dev/null || echo ""); \
				if [ -n "$$machine" ] && [ -n "$$distro" ] && [ -n "$$target" ]; then \
					echo -e "$(COLOR_GREEN)[$$total] ✓ $$board_name$(COLOR_RESET) ($$vendor | $$machine | $$distro | $$target)"; \
					passed_boards="$$passed_boards $$board_name"; \
					vendor_counts="$$vendor_counts\n$$vendor"; \
				else \
					echo -e "$(COLOR_YELLOW)[$$total] ✗ $$board_name$(COLOR_RESET) ($$vendor | MISSING: machine/distro/target)"; \
					failed_boards="$$failed_boards $$board_name"; \
				fi; \
			else \
				yaml_error=$$(python3 -c "import yaml; yaml.safe_load(open('$$yml_file'))" 2>&1); \
				echo -e "$(COLOR_YELLOW)[$$total] ✗ $$board_name$(COLOR_RESET) ($$vendor | YAML error: $$yaml_error)"; \
				failed_boards="$$failed_boards $$board_name"; \
			fi; \
		else \
			if [ -f "$$yml_file" ]; then \
				echo -e "$(COLOR_GREEN)[$$total] ? $$board_name$(COLOR_RESET) ($$vendor | file exists, python3 not available)"; \
				passed_boards="$$passed_boards $$board_name"; \
			else \
				echo -e "$(COLOR_YELLOW)[$$total] ✗ $$board_name$(COLOR_RESET) ($$vendor | file not found)"; \
				failed_boards="$$failed_boards $$board_name"; \
			fi; \
		fi; \
	done; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	passed_count=$$(echo $$passed_boards | wc -w); \
	failed_count=$$(echo $$failed_boards | wc -w); \
	echo ""; \
	echo -e "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================"; \
	echo -e "Configuration Validation Summary"; \
	echo -e "================================================================================$(COLOR_RESET)"; \
	echo -e "Total boards: $$total"; \
	echo -e "$(COLOR_GREEN)Valid:  $$passed_count$(COLOR_RESET)"; \
	echo -e "$(COLOR_YELLOW)Failed: $$failed_count$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
	echo ""; \
	echo -e "$(COLOR_BOLD)Boards by vendor:$(COLOR_RESET)"; \
	echo -e "$$vendor_counts" | grep -v "^$$" | sort | uniq -c | awk '{printf "  • %-25s %d boards\n", $$2, $$1}'; \
	if [ $$failed_count -gt 0 ]; then \
		echo ""; \
		echo -e "$(COLOR_YELLOW)Failed boards:$(COLOR_RESET)"; \
		for board in $$failed_boards; do \
			echo "  • $$board"; \
		done; \
		echo ""; \
		echo -e "$(COLOR_YELLOW)Tip: Run 'make dry-run <board-name>' to see detailed errors$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	echo ""; \
	echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ All board configurations are valid!$(COLOR_RESET)"; \
	echo ""; \
	echo -e "$(COLOR_BLUE)Note: This validates YAML syntax and required fields only.$(COLOR_RESET)"; \
	echo -e "$(COLOR_BLUE)For full source fetch + BitBake parse validation, use:$(COLOR_RESET)"; \
	echo -e "$(COLOR_BLUE)  make dry-run <board-name>$(COLOR_RESET)"

.PHONY: sdk
sdk: prerequisites docker-build
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make sdk <board-name>"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	yml_file=$$(find $(BOARDS_DIR) -name "$$board.yml" | head -1); \
	if [ -z "$$yml_file" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Board '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	board_build_dir="$(BUILD_DIR)/$$board"; \
	board_sources_dir="$(SOURCES_DIR)/$$board"; \
	start_time=$$(date +%s); \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting SDK build for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Creating build directory structure: $$board_build_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
	echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_sources_dir"; \
	echo -e "$(COLOR_GREEN)Starting SDK build...$(COLOR_RESET)"; \
	if $(DOCKER_RUN) \
		-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
		$(DOCKER_IMAGE) \
		kas build -c populate_sdk $(WORKSPACE_MOUNT)/$$yml_file; then \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ SDK build completed successfully for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "SDK artifacts located in: $$board_build_dir"; \
	else \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_RED)✗ SDK build failed for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
		echo -e "  • Check build logs: $$board_build_dir/tmp/log/"; \
		echo -e "  • SDK generation may require full image build first"; \
		echo -e "  • Verify populate_sdk target is supported"; \
		echo -e "  • Try: make build $$board && make sdk $$board"; \
		exit 1; \
	fi

.PHONY: esdk
esdk: prerequisites docker-build
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make esdk <board-name>"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	yml_file=$$(find $(BOARDS_DIR) -name "$$board.yml" | head -1); \
	if [ -z "$$yml_file" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Board '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	board_build_dir="$(BUILD_DIR)/$$board"; \
	board_sources_dir="$(SOURCES_DIR)/$$board"; \
	start_time=$$(date +%s); \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting eSDK build for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Creating build directory structure: $$board_build_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
	echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_sources_dir"; \
	echo -e "$(COLOR_GREEN)Starting eSDK build...$(COLOR_RESET)"; \
	if $(DOCKER_RUN) \
		-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
		$(DOCKER_IMAGE) \
		kas build -c populate_sdk_ext $(WORKSPACE_MOUNT)/$$yml_file; then \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ eSDK build completed successfully for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "eSDK artifacts located in: $$board_build_dir"; \
	else \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_RED)✗ eSDK build failed for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
		echo -e "  • Check build logs: $$board_build_dir/tmp/log/"; \
		echo -e "  • eSDK requires full image build first"; \
		echo -e "  • Verify populate_sdk_ext target is supported"; \
		echo -e "  • Try: make build $$board && make esdk $$board"; \
		exit 1; \
	fi

.PHONY: fetch
fetch: prerequisites docker-build
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make fetch <board-name>"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	yml_file=$$(find $(BOARDS_DIR) -name "$$board.yml" | head -1); \
	if [ -z "$$yml_file" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Board '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	board_build_dir="$(BUILD_DIR)/$$board"; \
	board_sources_dir="$(SOURCES_DIR)/$$board"; \
	start_time=$$(date +%s); \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Fetching sources for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Creating build directory structure: $$board_build_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
	echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_sources_dir"; \
	echo -e "$(COLOR_GREEN)Fetching sources for $$board...$(COLOR_RESET)"; \
	if $(DOCKER_RUN) \
		-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
		$(DOCKER_IMAGE) \
		kas checkout $(WORKSPACE_MOUNT)/$$yml_file; then \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ Sources fetched successfully for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "Sources located in: $$board_sources_dir"; \
	else \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_RED)✗ Fetch failed for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
		echo -e "  • Network connectivity issues"; \
		echo -e "  • Invalid repository URLs or branches in $$yml_file"; \
		echo -e "  • Authentication required for private repos"; \
		echo -e "  • Insufficient disk space"; \
		echo -e "  • Try: make clean $$board && make fetch $$board"; \
		exit 1; \
	fi

.PHONY: shell
shell: prerequisites docker-build
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make shell <board-name>"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	yml_file=$$(find $(BOARDS_DIR) -name "$$board.yml" | head -1); \
	if [ -z "$$yml_file" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Board '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make list' to see available boards"; \
		exit 1; \
	fi; \
	board_build_dir="$(BUILD_DIR)/$$board"; \
	board_sources_dir="$(SOURCES_DIR)/$$board"; \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting KAS shell for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Creating build directory structure: $$board_build_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
	echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
	mkdir -p "$$board_sources_dir"; \
	echo -e "$(COLOR_GREEN)Starting KAS shell for $$board...$(COLOR_RESET)"; \
	docker run --rm -it --network host \
		-v $(GIT_ROOT):$(WORKSPACE_MOUNT) \
		-w $(WORKSPACE_MOUNT) \
		--user $(shell id -u):$(shell id -g) \
		$(if $(HTTP_PROXY),-e HTTP_PROXY=$(HTTP_PROXY)) \
		$(if $(HTTPS_PROXY),-e HTTPS_PROXY=$(HTTPS_PROXY)) \
		$(if $(FTP_PROXY),-e FTP_PROXY=$(FTP_PROXY)) \
		$(if $(NO_PROXY),-e NO_PROXY=$(NO_PROXY)) \
		$(if $(http_proxy),-e http_proxy=$(http_proxy)) \
		$(if $(https_proxy),-e https_proxy=$(https_proxy)) \
		$(if $(ftp_proxy),-e ftp_proxy=$(ftp_proxy)) \
		$(if $(no_proxy),-e no_proxy=$(no_proxy)) \
		-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
		$(DOCKER_IMAGE) \
		kas shell $(WORKSPACE_MOUNT)/$$yml_file

.PHONY: copy-artifacts
copy-artifacts:
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make copy-artifacts <board-name>"; \
		exit 1; \
	fi; \
	if [ ! -d "$(BUILD_DIR)/$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: Build directory for '$$board' not found$(COLOR_RESET)"; \
		echo "Run 'make build $$board' first"; \
		exit 1; \
	fi; \
	start_time=$$(date +%s); \
	echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Copying artifacts for $$board$(COLOR_RESET)"; \
	echo -e "$(COLOR_GREEN)Copying artifacts for $$board to $(ARTIFACTS_DIR)/$$board$(COLOR_RESET)"; \
	mkdir -p "$(ARTIFACTS_DIR)/$$board"/{image,sdk,esdk}; \
	artifacts_found=false; \
	if [ -d "$(BUILD_DIR)/$$board/tmp/deploy/images" ]; then \
		echo -e "$(COLOR_GREEN)  → Copying images...$(COLOR_RESET)"; \
		cp -r "$(BUILD_DIR)/$$board/tmp/deploy/images"/* "$(ARTIFACTS_DIR)/$$board/image/" 2>/dev/null || true; \
		artifacts_found=true; \
	fi; \
	if [ -d "$(BUILD_DIR)/$$board/tmp/deploy/sdk" ]; then \
		echo -e "$(COLOR_GREEN)  → Copying SDK...$(COLOR_RESET)"; \
		cp -r "$(BUILD_DIR)/$$board/tmp/deploy/sdk"/* "$(ARTIFACTS_DIR)/$$board/sdk/" 2>/dev/null || true; \
		artifacts_found=true; \
	fi; \
	if compgen -G "$(BUILD_DIR)/$$board/tmp/deploy/sdk/*-toolchain-ext-*.sh" > /dev/null; then \
		echo -e "$(COLOR_GREEN)  → Copying eSDK...$(COLOR_RESET)"; \
		cp "$(BUILD_DIR)/$$board/tmp/deploy/sdk"/*-toolchain-ext-*.sh "$(ARTIFACTS_DIR)/$$board/esdk/" 2>/dev/null || true; \
		artifacts_found=true; \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	if [ "$$artifacts_found" = true ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ Artifacts copied to $(ARTIFACTS_DIR)/$$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "  Images: $(ARTIFACTS_DIR)/$$board/image/"; \
		echo -e "  SDK:    $(ARTIFACTS_DIR)/$$board/sdk/"; \
		echo -e "  eSDK:   $(ARTIFACTS_DIR)/$$board/esdk/"; \
	else \
		echo -e "$(COLOR_YELLOW)✗ No artifacts found for $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
		echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
		echo -e "  • Build may not have completed successfully"; \
		echo -e "  • Check if build directory exists: $(BUILD_DIR)/$$board"; \
		echo -e "  • Run 'make build $$board' first"; \
		exit 1; \
	fi

.PHONY: lint-yaml
lint-yaml:
	@start_time=$$(date +%s); \
	echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Linting YAML configuration files...$(COLOR_RESET)"; \
	echo ""; \
	failed_files=""; \
	total=0; \
	for yml_file in $$(find $(BOARDS_DIR) -name "*.yml" | sort); do \
		total=$$((total + 1)); \
		if command -v python3 >/dev/null 2>&1; then \
			if python3 -c "import yaml; yaml.safe_load(open('$$yml_file'))" 2>/dev/null; then \
				echo -e "$(COLOR_GREEN)✓ $$yml_file$(COLOR_RESET)"; \
			else \
				yaml_error=$$(python3 -c "import yaml; yaml.safe_load(open('$$yml_file'))" 2>&1); \
				echo -e "$(COLOR_RED)✗ $$yml_file$(COLOR_RESET)"; \
				echo -e "  $(COLOR_YELLOW)Error: $$yaml_error$(COLOR_RESET)"; \
				failed_files="$$failed_files $$yml_file"; \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)? $$yml_file$(COLOR_RESET) (python3 not available)"; \
		fi; \
	done; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo ""; \
	failed_count=$$(echo $$failed_files | wc -w); \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET) $$total files checked, $$failed_count failed"; \
	echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
	if [ $$failed_count -gt 0 ]; then \
		exit 1; \
	fi

# ==============================================================================
# Information targets
# ==============================================================================
.PHONY: list
list:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Available Boards:$(COLOR_RESET)\n"
	@for dir in $(BOARDS_DIR)/*/; do \
		group=$${dir#$(BOARDS_DIR)/}; \
		group=$${group%/}; \
		pretty_group=$$(echo "$$group" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $$i=toupper(substr($$i,1,1)) tolower(substr($$i,2)); print}'); \
		echo -e "$(COLOR_BOLD)$$pretty_group:$(COLOR_RESET)"; \
		find "$$dir" -name "*.yml" | sed 's|.yml$$||' | sed 's|.*/||' | sort | sed 's/^/  • /'; \
		echo; \
	done

.PHONY: info
info:
	@echo -e "$(COLOR_BOLD)Build System Information:$(COLOR_RESET)"
	@echo -e "  Version:         $(VERSION)"
	@echo -e "  Git Root:        $(GIT_ROOT)"
	@echo -e "  Build Directory: $(BUILD_DIR)"
	@echo -e "  Boards Directory: $(BOARDS_DIR)"
	@echo -e "  Sources Directory: $(SOURCES_DIR)"
	@echo -e "  Artifacts Directory: $(ARTIFACTS_DIR)"
	@echo -e "  Docker Image:    $(DOCKER_IMAGE)"
	@echo -e "  Workspace Mount: $(WORKSPACE_MOUNT)"
	@echo -e ""
	@echo -e "$(COLOR_BOLD)Existing Builds:$(COLOR_RESET)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		find $(BUILD_DIR) -maxdepth 1 -type d ! -name "$(BUILD_DIR)" -exec basename {} \; | sort | sed 's/^/  • /'; \
	else \
		echo "  No builds found"; \
	fi
	@echo -e ""
	@echo -e "$(COLOR_BOLD)Existing Sources:$(COLOR_RESET)"
	@if [ -d "$(SOURCES_DIR)" ]; then \
		find $(SOURCES_DIR) -maxdepth 1 -type d ! -name "$(SOURCES_DIR)" -exec basename {} \; | sort | sed 's/^/  • /'; \
	else \
		echo "  No sources found"; \
	fi

.PHONY: version
version:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)KAS Board Building System v$(VERSION)$(COLOR_RESET)"
	@echo -e "Built on: $(TIMESTAMP)"

.PHONY: help
help:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)KAS Board Building System v$(VERSION)$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Usage:$(COLOR_RESET)"
	@echo -e "  make build <board-name>        Build a specific board configuration"
	@echo -e "  make dry-run <board-name>      Fetch sources + validate (parse only, no build)"
	@echo -e "  make dry-run-all               Fast YAML validation for all boards"
	@echo -e "  make sdk <board-name>          Build SDK for a board"
	@echo -e "  make esdk <board-name>         Build eSDK (Extensible SDK) for a board"
	@echo -e "  make copy-artifacts <board>    Copy build artifacts to artifacts/ directory"
	@echo -e "  make fetch <board-name>        Fetch sources for a board (no build)"
	@echo -e "  make shell <board-name>        Open interactive shell in build environment"
	@echo -e "  make list                      List all available boards"
	@echo -e "  make info                      Show build system information"
	@echo -e "  make version                   Show version information"
	@echo -e "  make lint-yaml                 Lint all YAML configuration files"
	@echo -e "  make clean <board-name>        Clean build artifacts for a board"
	@echo -e "  make clean-all                 Clean all build artifacts"
	@echo -e "  make docker-build              Build the Docker image"
	@echo -e "  make docker-run                Run Docker container interactively"
	@echo -e "  make prerequisites             Check system prerequisites"
	@echo -e "  make help                      Show this help message"
	@echo ""
	@echo -e "$(COLOR_BOLD)Tab Completion:$(COLOR_RESET)"
	@echo -e "  source make-completion.bash    Enable bash tab completion for make commands"
	@echo ""
	@echo -e "$(COLOR_BOLD)Proxy Configuration:$(COLOR_RESET)"
	@echo -e "  If behind a proxy, set environment variables before running make:"
	@echo -e "  export HTTP_PROXY=http://proxy.example.com:8080"
	@echo -e "  export HTTPS_PROXY=http://proxy.example.com:8080"
	@echo ""
	@echo -e "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo -e "  make build raspberrypi-4-model-b"
	@echo -e "  make dry-run zynqmp-zcu102"
	@echo -e "  make dry-run-all"
	@echo -e "  make sdk imx8m-plus-evk"
	@echo -e "  make esdk raspberrypi-4-model-b"
	@echo -e "  make copy-artifacts raspberrypi-4-model-b"
	@echo -e "  make fetch imx8m-plus-evk"
	@echo -e "  make shell raspberrypi-4-model-b"
	@echo -e "  make clean raspberrypi-4-model-b"

# ==============================================================================
# Clean targets
# ==============================================================================
.PHONY: clean-all
clean-all:
	@echo -e "$(COLOR_YELLOW)Warning: This will remove all build artifacts and sources$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo -e "$(COLOR_YELLOW)Removing all build artifacts and sources...$(COLOR_RESET)"; \
		rm -rf $(BUILD_DIR); \
		rm -rf $(SOURCES_DIR); \
		echo -e "$(COLOR_GREEN)✓ All build artifacts and sources removed$(COLOR_RESET)"; \
	else \
		echo "Cancelled"; \
	fi

.PHONY: clean
clean: 
	@board=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Error: No board specified$(COLOR_RESET)"; \
		echo "Usage: make clean <board-name>"; \
		echo "Or use: make clean-all (removes everything)"; \
		exit 1; \
	fi; \
	start_time=$$(date +%s); \
	if [ -d "$(BUILD_DIR)/$$board" ] || [ -d "$(SOURCES_DIR)/$$board" ]; then \
		echo -e "$(COLOR_YELLOW)Removing build artifacts and sources for $$board...$(COLOR_RESET)"; \
		rm -rf "$(BUILD_DIR)/$$board"; \
		rm -rf "$(SOURCES_DIR)/$$board"; \
		end_time=$$(date +%s); \
		duration=$$((end_time - start_time)); \
		echo -e "$(COLOR_GREEN)✓ Cleaned $$board$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_YELLOW)No build artifacts or sources found for $$board$(COLOR_RESET)"; \
	fi

# ==============================================================================
# Docker targets
# ==============================================================================
.PHONY: docker-build
docker-build:
	@if docker images -q $(DOCKER_IMAGE) | grep -q .; then \
		echo -e "$(COLOR_GREEN)✓ Docker image $(DOCKER_IMAGE) already exists, skipping build$(COLOR_RESET)"; \
	else \
		start_time=$$(date +%s); \
		echo -e "$(COLOR_BLUE)Building Docker image...$(COLOR_RESET)"; \
		if $(MAKE) -C docker build; then \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_GREEN)✓ Docker image built successfully$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		else \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_YELLOW)✗ Docker build failed$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Error details:$(COLOR_RESET)"; \
			echo -e "  • Check Docker daemon is running"; \
			echo -e "  • Verify Dockerfile in docker/ directory"; \
			echo -e "  • Check available disk space"; \
			echo -e "  • Try: docker system prune && make docker-build"; \
			exit 1; \
		fi; \
	fi

.PHONY: docker-run
docker-run:
	@$(MAKE) -C docker run

# ==============================================================================
# Catch-all target for board names (prevents "No rule to make target" errors)
# ==============================================================================
%:
	@:

.PHONY: docker-clean
docker-clean:
	@$(MAKE) -C docker clean

.PHONY: docker
docker: docker-build