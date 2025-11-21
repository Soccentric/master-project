# ==============================================================================
# Professional Makefile for KAS-based Board Building System
# Version: 2.0.0
# ==============================================================================

# Variables
SHELL := /bin/bash
.ONESHELL:  # Use one shell for multi-line commands
GIT_ROOT := $(shell pwd)
BUILD_DIR := build
BOARDS_DIR := boards
SOURCES_DIR := sources
ARTIFACTS_DIR := artifacts
SHARED_DIR := shared
SHARED_DL_DIR := $(SHARED_DIR)/downloads
SHARED_SSTATE_BASE_DIR := $(SHARED_DIR)/sstate-cache
DOCKER_IMAGE := master-builder:latest
WORKSPACE_MOUNT := /workspace
VERSION := 2.1.0
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Load user configuration if it exists
-include .builderrc

# Build configuration (can be overridden)
BUILD_VARIANT ?= release
BB_NUMBER_THREADS ?= $(shell nproc)
PARALLEL_MAKE ?= -j $(shell nproc)
RM_WORK ?= 1

# Prerequisites check
REQUIRED_TOOLS := docker git
define CHECK_TOOLS
	@clear; \
	for tool in $(REQUIRED_TOOLS); do \
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
COLOR_CYAN := \033[36m
COLOR_MAGENTA := \033[35m
COLOR_WHITE := \033[37m

# ==============================================================================
# Default target
# ==============================================================================
.DEFAULT_GOAL := help

.PHONY: all
all: help

# ==============================================================================
# Setup bash completion
# ==============================================================================
.PHONY: setup-completion
setup-completion:
	@clear; if [ -f "$(GIT_ROOT)/make-completion.bash" ]; then \
		echo -e "$(COLOR_BLUE)Setting up bash completion...$(COLOR_RESET)"; \
		if grep -q "source.*make-completion.bash" ~/.bashrc 2>/dev/null; then \
			echo -e "$(COLOR_GREEN)✓ Bash completion already configured in ~/.bashrc$(COLOR_RESET)"; \
		else \
			echo "" >> ~/.bashrc; \
			echo "# KAS Build System tab completion" >> ~/.bashrc; \
			echo "if [ -f \"$(GIT_ROOT)/make-completion.bash\" ]; then" >> ~/.bashrc; \
			echo "    source \"$(GIT_ROOT)/make-completion.bash\"" >> ~/.bashrc; \
			echo "fi" >> ~/.bashrc; \
			echo -e "$(COLOR_GREEN)✓ Bash completion added to ~/.bashrc$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Run: source ~/.bashrc (or restart your terminal)$(COLOR_RESET)"; \
		fi; \
		source "$(GIT_ROOT)/make-completion.bash"; \
		echo -e "$(COLOR_GREEN)✓ Tab completion active for this session$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_RED)✗ make-completion.bash not found$(COLOR_RESET)"; \
		exit 1; \
	fi

# ==============================================================================
# Prerequisites
# ==============================================================================
.PHONY: prerequisites
prerequisites:
	$(CHECK_TOOLS)
	@echo -e "$(COLOR_GREEN)✓ All prerequisites satisfied$(COLOR_RESET)"

.PHONY: doctor
doctor:
	@clear; echo -e "$(COLOR_BLUE)Running comprehensive system diagnostics...$(COLOR_RESET)"
	@echo ""
	@./scripts/preflight-check.sh

.PHONY: preflight
preflight:
	@./scripts/preflight-check.sh "$${args[@]}"

# ==============================================================================
# Build targets
# ==============================================================================
.PHONY: build
build: prerequisites docker-build
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 3 ]; then \
		family="$${args[0]}"; \
		machine="$${args[1]}"; \
		target="$${args[2]}"; \
		if ! ./scripts/validate-target.sh "$$family" "$$machine" "$$target"; then \
			exit 1; \
		fi; \
		yml_file="$(BOARDS_DIR)/$$family/$$family.yml"; \
		if [ ! -f "$$yml_file" ]; then \
			echo -e "$(COLOR_RED)Error: Configuration file not found: $$yml_file$(COLOR_RESET)"; \
			exit 1; \
		fi; \
		build_name="$$family-$$machine"; \
		board_build_dir="$(BUILD_DIR)/$$build_name"; \
		board_sources_dir="$(SOURCES_DIR)/$$family"; \
		arch_map_file="$(BOARDS_DIR)/$$family/.arch-map"; \
		if [ -f "$$arch_map_file" ]; then \
			arch=$$(grep "^$$machine:" "$$arch_map_file" | cut -d: -f2); \
			if [ -z "$$arch" ]; then \
				echo -e "$(COLOR_YELLOW)Warning: Architecture not found for $$machine, defaulting to aarch64$(COLOR_RESET)"; \
				arch="aarch64"; \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)Warning: Architecture map not found, defaulting to aarch64$(COLOR_RESET)"; \
			arch="aarch64"; \
		fi; \
		board_sstate_dir="$(SHARED_SSTATE_BASE_DIR)/$$family-$$arch"; \
		temp_yml="/tmp/kas-$$family-$$machine-$$$$.yml"; \
		mkdir -p "$(SHARED_DL_DIR)" "$$board_sstate_dir"; \
		sed -e "s/__MACHINE__/$$machine/g" -e "s/__TARGET__/$$target/g" "$$yml_file" > "$$temp_yml"; \
		start_time=$$(date +%s); \
		./scripts/build-history.sh start "$$family" "$$machine" "$$target" "$(BUILD_VARIANT)"; \
		echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting build$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Family:  $$family$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Machine: $$machine$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Target:  $$target$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Arch:    $$arch$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Variant: $(BUILD_VARIANT)$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Threads: $(BB_NUMBER_THREADS) (BB_NUMBER_THREADS), $(PARALLEL_MAKE) (PARALLEL_MAKE)$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Creating build directory: $$board_build_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_build_dir"/{tmp,cache,conf,conf/multiconfig}; \
		touch "$$board_build_dir/conf/multiconfig/.conf"; \
		echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_sources_dir"; \
		echo -e "$(COLOR_GREEN)Using shared caches:$(COLOR_RESET)"; \
		echo -e "  Downloads: $(SHARED_DL_DIR)"; \
		echo -e "  SSTATE:    $$board_sstate_dir ($$family/$$arch)"; \
		echo -e "$(COLOR_GREEN)Starting KAS build...$(COLOR_RESET)"; \
		if $(DOCKER_RUN) \
			-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
			-e BUILD_VARIANT=$(BUILD_VARIANT) \
			-e BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) \
			-e "PARALLEL_MAKE=$(PARALLEL_MAKE)" \
			-e RM_WORK=$(RM_WORK) \
			-e DL_DIR=$(WORKSPACE_MOUNT)/$(SHARED_DL_DIR) \
			-e SSTATE_DIR=$(WORKSPACE_MOUNT)/$$board_sstate_dir \
			-v "$$temp_yml:$(WORKSPACE_MOUNT)/.kas-temp.yml:ro" \
			$(DOCKER_IMAGE) \
			kas build $(WORKSPACE_MOUNT)/.kas-temp.yml; then \
			rm -f "$$temp_yml"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			./scripts/build-history.sh end "$$family" "$$machine" "$$target" "SUCCESS" "$$start_time"; \
			echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ Build completed successfully$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "Build artifacts: $$board_build_dir"; \
			echo -e "Sources: $$board_sources_dir"; \
		else \
			rm -f "$$temp_yml"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			./scripts/build-history.sh end "$$family" "$$machine" "$$target" "FAILED" "$$start_time"; \
			echo -e "$(COLOR_RED)✗ Build failed$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Check logs: $$board_build_dir/tmp/log/$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)To resume: make build $$family $$machine $$target$(COLOR_RESET)"; \
			exit 1; \
		fi; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make build <family> <machine> <target> [BUILD_VARIANT=debug|release|production]"; \
		echo ""; \
		echo "Example: make build raspberry-pi raspberrypi5 core-image-base"; \
		echo "         make build raspberry-pi raspberrypi5 core-image-base BUILD_VARIANT=debug"; \
		echo ""; \
		echo "Available families:"; \
		echo "  • raspberry-pi"; \
		echo "  • xilinx-zynq"; \
		echo "  • nvidia-jetson"; \
		echo "  • nxp-imx"; \
		exit 1; \
	fi

.PHONY: sdk
sdk: prerequisites docker-build
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 3 ]; then \
		family="$${args[0]}"; \
		machine="$${args[1]}"; \
		target="$${args[2]}"; \
		if ! ./scripts/validate-target.sh "$$family" "$$machine" "$$target"; then \
			exit 1; \
		fi; \
		yml_file="$(BOARDS_DIR)/$$family/$$family.yml"; \
		if [ ! -f "$$yml_file" ]; then \
			echo -e "$(COLOR_RED)Error: Configuration file not found: $$yml_file$(COLOR_RESET)"; \
			exit 1; \
		fi; \
		build_name="$$family-$$machine"; \
		board_build_dir="$(BUILD_DIR)/$$build_name"; \
		board_sources_dir="$(SOURCES_DIR)/$$family"; \
		temp_yml="/tmp/kas-$$family-$$machine-$$$$.yml"; \
		sed -e "s/__MACHINE__/$$machine/g" -e "s/__TARGET__/$$target/g" "$$yml_file" > "$$temp_yml"; \
		start_time=$$(date +%s); \
		echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting SDK build$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Family:  $$family$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Machine: $$machine$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Target:  $$target$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Creating build directory: $$board_build_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
		echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_sources_dir"; \
		echo -e "$(COLOR_GREEN)Starting SDK build...$(COLOR_RESET)"; \
		if $(DOCKER_RUN) \
			-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
			-v "$$temp_yml:$(WORKSPACE_MOUNT)/.kas-temp.yml:ro" \
			$(DOCKER_IMAGE) \
			kas build -c populate_sdk $(WORKSPACE_MOUNT)/.kas-temp.yml; then \
			rm -f "$$temp_yml"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_GREEN)✓ SDK build completed successfully$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "SDK artifacts: $$board_build_dir"; \
			sdk_file=$$(find "$$board_build_dir/tmp/deploy/sdk" -name "*.sh" -type f 2>/dev/null | head -n 1); \
			if [ -n "$$sdk_file" ]; then \
				sdk_file_abs="$(GIT_ROOT)/$$sdk_file"; \
				echo -e "$(COLOR_BLUE)Building SDK Docker image...$(COLOR_RESET)"; \
				echo -e "  SDK file: $$sdk_file_abs"; \
				echo -e "  Family: $$family"; \
				if $(MAKE) -C docker/sdk build SDK_FILE="$$sdk_file_abs" MACHINE_FAMILY="$$family"; then \
					echo -e "$(COLOR_GREEN)✓ SDK Docker image built successfully$(COLOR_RESET)"; \
					echo -e "  Image: sdk-build-$$family:latest"; \
				else \
					echo -e "$(COLOR_YELLOW)⚠ SDK Docker image build failed$(COLOR_RESET)"; \
				fi; \
			else \
				echo -e "$(COLOR_YELLOW)⚠ No SDK installer found in $$board_build_dir/tmp/deploy/sdk$(COLOR_RESET)"; \
			fi;
		else \
			rm -f "$$temp_yml"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_RED)✗ SDK build failed$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Check logs: $$board_build_dir/tmp/log/$(COLOR_RESET)"; \
			exit 1; \
		fi; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make sdk <family> <machine> <target>"; \
		echo "Example: make sdk raspberry-pi raspberrypi5 core-image-base"; \
		exit 1; \
	fi

.PHONY: shell
shell: prerequisites docker-build
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 3 ]; then \
		family="$${args[0]}"; \
		machine="$${args[1]}"; \
		target="$${args[2]}"; \
		if ! ./scripts/validate-target.sh "$$family" "$$machine" "$$target"; then \
			exit 1; \
		fi; \
		yml_file="$(BOARDS_DIR)/$$family/$$family.yml"; \
		if [ ! -f "$$yml_file" ]; then \
			echo -e "$(COLOR_RED)Error: Configuration file not found: $$yml_file$(COLOR_RESET)"; \
			exit 1; \
		fi; \
		build_name="$$family-$$machine"; \
		board_build_dir="$(BUILD_DIR)/$$build_name"; \
		board_sources_dir="$(SOURCES_DIR)/$$family"; \
		arch_map_file="$(BOARDS_DIR)/$$family/.arch-map"; \
		if [ -f "$$arch_map_file" ]; then \
			arch=$$(grep "^$$machine:" "$$arch_map_file" | cut -d: -f2); \
			if [ -z "$$arch" ]; then \
				arch="aarch64"; \
			fi; \
		else \
			arch="aarch64"; \
		fi; \
		board_sstate_dir="$(SHARED_SSTATE_BASE_DIR)/$$family-$$arch"; \
		temp_yml="/tmp/kas-$$family-$$machine-$$$$.yml"; \
		mkdir -p "$(SHARED_DL_DIR)" "$$board_sstate_dir"; \
		sed -e "s/__MACHINE__/$$machine/g" -e "s/__TARGET__/$$target/g" "$$yml_file" > "$$temp_yml"; \
		echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting interactive shell$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Family:  $$family$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Machine: $$machine$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Target:  $$target$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Arch:    $$arch$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Creating build directory: $$board_build_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_build_dir"; \
		echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_sources_dir"; \
		echo -e "$(COLOR_GREEN)Using shared caches:$(COLOR_RESET)"; \
		echo -e "  Downloads: $(SHARED_DL_DIR)"; \
		echo -e "  SSTATE:    $$board_sstate_dir ($$family/$$arch)"; \
		echo -e "$(COLOR_GREEN)Starting KAS shell...$(COLOR_RESET)"; \
		$(DOCKER_RUN) -it \
			-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
			-e BUILD_VARIANT=$(BUILD_VARIANT) \
			-e BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) \
			-e "PARALLEL_MAKE=$(PARALLEL_MAKE)" \
			-e RM_WORK=$(RM_WORK) \
			-e DL_DIR=$(WORKSPACE_MOUNT)/$(SHARED_DL_DIR) \
			-e SSTATE_DIR=$(WORKSPACE_MOUNT)/$$board_sstate_dir \
			-v "$$temp_yml:$(WORKSPACE_MOUNT)/.kas-temp.yml:ro" \
			$(DOCKER_IMAGE) \
			kas shell $(WORKSPACE_MOUNT)/.kas-temp.yml; \
		rm -f "$$temp_yml"; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make shell <family> <machine> <target>"; \
		echo "Example: make shell raspberry-pi raspberrypi5 core-image-base"; \
		exit 1; \
	fi

.PHONY: esdk
esdk: prerequisites docker-build
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 3 ]; then \
		family="$${args[0]}"; \
		machine="$${args[1]}"; \
		target="$${args[2]}"; \
		if ! ./scripts/validate-target.sh "$$family" "$$machine" "$$target"; then \
			exit 1; \
		fi; \
		yml_file="$(BOARDS_DIR)/$$family/$$family.yml"; \
		if [ ! -f "$$yml_file" ]; then \
			echo -e "$(COLOR_RED)Error: Configuration file not found: $$yml_file$(COLOR_RESET)"; \
			exit 1; \
		fi; \
		build_name="$$family-$$machine"; \
		board_build_dir="$(BUILD_DIR)/$$build_name"; \
		board_sources_dir="$(SOURCES_DIR)/$$family"; \
		temp_yml="/tmp/kas-$$family-$$machine-$$$$.yml"; \
		sed -e "s/__MACHINE__/$$machine/g" -e "s/__TARGET__/$$target/g" "$$yml_file" > "$$temp_yml"; \
		start_time=$$(date +%s); \
		echo -e "$(COLOR_BLUE)[$$(date +%Y%m%d_%H%M%S)] Starting eSDK build$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Family:  $$family$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Machine: $$machine$(COLOR_RESET)"; \
		echo -e "$(COLOR_BLUE)  Target:  $$target$(COLOR_RESET)"; \
		echo -e "$(COLOR_GREEN)Creating build directory: $$board_build_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_build_dir"/{tmp,cache,conf}; \
		echo -e "$(COLOR_GREEN)Creating sources directory: $$board_sources_dir$(COLOR_RESET)"; \
		mkdir -p "$$board_sources_dir"; \
		echo -e "$(COLOR_GREEN)Starting eSDK build...$(COLOR_RESET)"; \
		if $(DOCKER_RUN) \
			-e KAS_BUILD_DIR=$(WORKSPACE_MOUNT)/$$board_build_dir \
			-v "$$temp_yml:$(WORKSPACE_MOUNT)/.kas-temp.yml:ro" \
			$(DOCKER_IMAGE) \
			kas build -c populate_sdk_ext $(WORKSPACE_MOUNT)/.kas-temp.yml; then \
			rm -f "$$temp_yml"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_BOLD)$(COLOR_GREEN)✓ eSDK build completed successfully$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "eSDK artifacts: $$board_build_dir"; \
			esdk_file=$$(find "$$board_build_dir/tmp/deploy/sdk" -name "*.sh" -type f 2>/dev/null | head -n 1); \
			if [ -n "$$esdk_file" ]; then \
				echo -e "$(COLOR_BLUE)Building eSDK Docker image...$(COLOR_RESET)"; \
				echo -e "  eSDK file: $$esdk_file"; \
				echo -e "  Family: $$family"; \
				if $(MAKE) -C docker/esdk build ESDK_FILE="$$esdk_file" MACHINE_FAMILY="$$family"; then \
					echo -e "$(COLOR_GREEN)✓ eSDK Docker image built successfully$(COLOR_RESET)"; \
					echo -e "  Image: esdk-build-$$family:latest"; \
				else \
					echo -e "$(COLOR_YELLOW)⚠ eSDK Docker image build failed$(COLOR_RESET)"; \
				fi; \
			else \
				echo -e "$(COLOR_YELLOW)⚠ No eSDK installer found in $$board_build_dir/tmp/deploy/sdk$(COLOR_RESET)"; \
			fi; \
		else \
			rm -f "$$temp_yml"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_RED)✗ eSDK build failed$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Duration: $$duration seconds$(COLOR_RESET)"; \
			echo -e "$(COLOR_YELLOW)Check logs: $$board_build_dir/tmp/log/$(COLOR_RESET)"; \
			exit 1; \
		fi; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make esdk <family> <machine> <target>"; \
		echo "Example: make esdk raspberry-pi raspberrypi5 core-image-base"; \
		exit 1; \
	fi

# ==============================================================================
# Information targets
# ==============================================================================
.PHONY: list
list:
	@clear; echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Available Board Families:$(COLOR_RESET)\n"
	@echo -e "$(COLOR_BOLD)Raspberry Pi:$(COLOR_RESET)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Family:" "raspberry-pi"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Config:" "boards/raspberry-pi/raspberry-pi.yml"
	@echo -e "  $(COLOR_YELLOW)Machines:$(COLOR_RESET)"
	@grep -v "^#" boards/raspberry-pi/.machines | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo -e "  $(COLOR_YELLOW)Targets:$(COLOR_RESET)"
	@grep -v "^#" boards/raspberry-pi/.targets | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo ""
	@echo -e "$(COLOR_BOLD)Xilinx Zynq:$(COLOR_RESET)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Family:" "xilinx-zynq"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Config:" "boards/xilinx-zynq/xilinx-zynq.yml"
	@echo -e "  $(COLOR_YELLOW)Machines:$(COLOR_RESET)"
	@grep -v "^#" boards/xilinx-zynq/.machines | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo -e "  $(COLOR_YELLOW)Targets:$(COLOR_RESET)"
	@grep -v "^#" boards/xilinx-zynq/.targets | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo ""
	@echo -e "$(COLOR_BOLD)NVIDIA Jetson:$(COLOR_RESET)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Family:" "nvidia-jetson"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Config:" "boards/nvidia-jetson/nvidia-jetson.yml"
	@echo -e "  $(COLOR_YELLOW)Machines:$(COLOR_RESET)"
	@grep -v "^#" boards/nvidia-jetson/.machines | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo -e "  $(COLOR_YELLOW)Targets:$(COLOR_RESET)"
	@grep -v "^#" boards/nvidia-jetson/.targets | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo ""
	@echo -e "$(COLOR_BOLD)NXP i.MX:$(COLOR_RESET)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Family:" "nxp-imx"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  Config:" "boards/nxp-imx/nxp-imx.yml"
	@echo -e "  $(COLOR_YELLOW)Machines:$(COLOR_RESET)"
	@grep -v "^#" boards/nxp-imx/.machines | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'
	@echo -e "  $(COLOR_YELLOW)Targets:$(COLOR_RESET)"
	@grep -v "^#" boards/nxp-imx/.targets | grep -v "^$$" | sed 's/^/    $(COLOR_GREEN)•$(COLOR_RESET) /'

.PHONY: info
info:
	@clear; echo -e "$(COLOR_BOLD)Build System Information:$(COLOR_RESET)"
	@echo ""
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Version:" "$(VERSION)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Git Root:" "$(GIT_ROOT)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Build Directory:" "$(BUILD_DIR)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Boards Directory:" "$(BOARDS_DIR)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Sources Directory:" "$(SOURCES_DIR)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Artifacts Directory:" "$(ARTIFACTS_DIR)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Shared DL Dir:" "$(SHARED_DL_DIR)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "SSTATE Base Dir:" "$(SHARED_SSTATE_BASE_DIR) (family-arch-specific subdirs)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Docker Image:" "$(DOCKER_IMAGE)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Workspace Mount:" "$(WORKSPACE_MOUNT)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Build Configuration:$(COLOR_RESET)"
	@echo ""
	@printf "$(COLOR_YELLOW)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Default Variant:" "$(BUILD_VARIANT)"
	@printf "$(COLOR_YELLOW)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BB_NUMBER_THREADS:" "$(BB_NUMBER_THREADS)"
	@printf "$(COLOR_YELLOW)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "PARALLEL_MAKE:" "$(PARALLEL_MAKE)"
	@printf "$(COLOR_YELLOW)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "RM_WORK:" "$(RM_WORK)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Shared Cache Usage:$(COLOR_RESET)"
	@echo ""
	@if [ -d "$(SHARED_DL_DIR)" ]; then \
		dl_size=$$(du -sh "$(SHARED_DL_DIR)" 2>/dev/null | cut -f1); \
		printf "$(COLOR_GREEN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Downloads:" "$$dl_size"; \
	else \
		printf "$(COLOR_RED)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "Downloads:" "Not initialized"; \
	fi
	@if [ -d "$(SHARED_SSTATE_BASE_DIR)" ]; then \
		sstate_size=$$(du -sh "$(SHARED_SSTATE_BASE_DIR)" 2>/dev/null | cut -f1); \
		printf "$(COLOR_GREEN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "SSTATE:" "$$sstate_size (all families)"; \
		for family_dir in $(SHARED_SSTATE_BASE_DIR)/*; do \
			if [ -d "$$family_dir" ]; then \
				family_name=$$(basename "$$family_dir"); \
				family_size=$$(du -sh "$$family_dir" 2>/dev/null | cut -f1); \
				printf "$(COLOR_BLUE)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "  $$family_name:" "$$family_size"; \
			fi; \
		done; \
	else \
		printf "$(COLOR_RED)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "SSTATE:" "Not initialized"; \
	fi
	@echo ""
	@echo -e "$(COLOR_BOLD)Existing Builds:$(COLOR_RESET)"
	@echo ""
	@if [ -d "$(BUILD_DIR)" ]; then \
		find $(BUILD_DIR) -maxdepth 1 -type d ! -name "$(BUILD_DIR)" -exec basename {} \; | sort | sed 's/^/  $(COLOR_GREEN)•$(COLOR_RESET) /'; \
	else \
		echo "  $(COLOR_RED)No builds found$(COLOR_RESET)"; \
	fi
	@echo ""
	@echo -e "$(COLOR_BOLD)Existing Sources:$(COLOR_RESET)"
	@echo ""
	@if [ -d "$(SOURCES_DIR)" ]; then \
		find $(SOURCES_DIR) -maxdepth 1 -type d ! -name "$(SOURCES_DIR)" -exec basename {} \; | sort | sed 's/^/  $(COLOR_GREEN)•$(COLOR_RESET) /'; \
	else \
		echo "  $(COLOR_RED)No sources found$(COLOR_RESET)"; \
	fi

.PHONY: version
version:
	@clear; echo -e "$(COLOR_BOLD)$(COLOR_BLUE)KAS Board Building System v$(VERSION)$(COLOR_RESET)"
	@echo -e "Built on: $(TIMESTAMP)"

.PHONY: history
history:
	@clear; ./scripts/build-history.sh show

.PHONY: stats
stats:
	@clear; ./scripts/build-history.sh stats

.PHONY: help
help:
	@clear; echo -e "$(COLOR_BOLD)$(COLOR_BLUE)KAS Board Building System v$(VERSION)$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Available Commands:$(COLOR_RESET)"
	@echo ""
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make build <family> <machine> <target>" "Build a board configuration"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make sdk <family> <machine> <target>" "Build SDK for a board"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make esdk <family> <machine> <target>" "Build eSDK for a board"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make shell <family> <machine> <target>" "Start interactive shell in build environment"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make collect-artifacts <family-machine>" "Collect build artifacts to artifacts/"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make list" "List all available families, machines, and targets"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make info" "Show build system information"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make config" "Show/modify build configuration"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make version" "Show version information"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make history" "Show build history"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make stats" "Show build statistics"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make doctor" "Run comprehensive system diagnostics"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make clean <family-machine>" "Clean build artifacts"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make clean-all" "Clean all build artifacts"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make clean-shared" "Clean shared caches (downloads + sstate)"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make clean-sstate-family <family>" "Clean sstate cache for specific family"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make docker-build" "Build the Docker image"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make setup-completion" "Setup bash tab completion"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make prerequisites" "Check system prerequisites"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make help" "Show this help message"
	@echo ""
	@echo -e "$(COLOR_BOLD)Build Variants:$(COLOR_RESET)"
	@printf "$(COLOR_YELLOW)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BUILD_VARIANT=debug" "Debug build with extra logging and symbols"
	@printf "$(COLOR_YELLOW)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BUILD_VARIANT=release" "Optimized production build (default)"
	@printf "$(COLOR_YELLOW)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BUILD_VARIANT=production" "Hardened production build"
	@echo ""
	@echo -e "$(COLOR_BOLD)Performance Options:$(COLOR_RESET)"
	@printf "$(COLOR_GREEN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BB_NUMBER_THREADS=N" "BitBake parallel tasks (default: nproc)"
	@printf "$(COLOR_GREEN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "PARALLEL_MAKE=N" "Make parallel jobs (default: nproc)"
	@printf "$(COLOR_GREEN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "RM_WORK=0|1" "Remove work files after build (default: 1)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Available Families:$(COLOR_RESET)"
	@printf "$(COLOR_MAGENTA)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "• raspberry-pi" "Raspberry Pi boards"
	@printf "$(COLOR_MAGENTA)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "• xilinx-zynq" "Xilinx Zynq/ZynqMP/Versal boards"
	@printf "$(COLOR_MAGENTA)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "• nvidia-jetson" "NVIDIA Jetson boards"
	@printf "$(COLOR_MAGENTA)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "• nxp-imx" "NXP i.MX boards"
	@echo ""
	@echo -e "$(COLOR_BOLD)Tab Completion:$(COLOR_RESET)"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "make setup-completion" "Setup automatic tab completion"
	@printf "$(COLOR_CYAN)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "source make-completion.bash" "Enable for current session only"
	@echo ""
	@echo -e "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo -e "  make build raspberry-pi raspberrypi5 core-image-base"
	@echo -e "  make build raspberry-pi raspberrypi5 core-image-base BUILD_VARIANT=debug"
	@echo -e "  make build raspberry-pi raspberrypi4 core-image-base BB_NUMBER_THREADS=8"
	@echo -e "  make sdk raspberry-pi raspberrypi4 core-image-base"
	@echo -e "  make esdk nvidia-jetson jetson-agx-orin-devkit core-image-base"
	@echo -e "  make shell raspberry-pi raspberrypi5 core-image-base"
	@echo -e "  make collect-artifacts raspberry-pi-raspberrypi5"
	@echo -e "  make build xilinx-zynq zynqmp-zcu102 petalinux-image-minimal"
	@echo -e "  make build nxp-imx imx8mpevk core-image-minimal"
	@echo -e "  make list"
	@echo -e "  make clean raspberry-pi-raspberrypi5"

# ==============================================================================
# Clean targets
# ==============================================================================
.PHONY: clean-shared
clean-shared: clean-downloads clean-sstate

.PHONY: clean-downloads
clean-downloads:
	@clear; echo -e "$(COLOR_YELLOW)Warning: This will remove the shared downloads cache$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo -e "$(COLOR_YELLOW)Removing shared downloads...$(COLOR_RESET)"; \
		rm -rf $(SHARED_DL_DIR); \
		echo -e "$(COLOR_GREEN)✓ Shared downloads removed$(COLOR_RESET)"; \
	else \
		echo "Cancelled"; \
	fi

.PHONY: clean-sstate
clean-sstate:
	@clear; echo -e "$(COLOR_YELLOW)Warning: This will remove the shared sstate cache (all families)$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo -e "$(COLOR_YELLOW)Removing shared sstate...$(COLOR_RESET)"; \
		rm -rf $(SHARED_SSTATE_BASE_DIR); \
		echo -e "$(COLOR_GREEN)✓ Shared sstate removed$(COLOR_RESET)"; \
	else \
		echo "Cancelled"; \
	fi

.PHONY: clean-sstate-family
clean-sstate-family:
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 1 ]; then \
		family="$${args[0]}"; \
		family_sstate_dir="$(SHARED_SSTATE_BASE_DIR)/$$family"; \
		if [ -d "$$family_sstate_dir" ]; then \
			echo -e "$(COLOR_YELLOW)Warning: This will remove sstate cache for $$family$(COLOR_RESET)"; \
			read -p "Are you sure? [y/N] " -n 1 -r; \
			echo; \
			if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
				echo -e "$(COLOR_YELLOW)Removing $$family sstate cache...$(COLOR_RESET)"; \
				rm -rf "$$family_sstate_dir"; \
				echo -e "$(COLOR_GREEN)✓ SSTATE cache for $$family removed$(COLOR_RESET)"; \
			else \
				echo "Cancelled"; \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)No sstate cache found for $$family$(COLOR_RESET)"; \
		fi; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make clean-sstate-family <family>"; \
		echo "Example: make clean-sstate-family raspberry-pi"; \
		exit 1; \
	fi

.PHONY: clean-all
clean-all:
	@clear; echo -e "$(COLOR_YELLOW)Removing all build artifacts and sources...$(COLOR_RESET)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(SOURCES_DIR)
	@echo -e "$(COLOR_GREEN)✓ All build artifacts and sources removed$(COLOR_RESET)"

.PHONY: clean
clean: 
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 1 ]; then \
		build_name="$${args[0]}"; \
		start_time=$$(date +%s); \
		if [ -d "$(BUILD_DIR)/$$build_name" ] || [ -d "$(SOURCES_DIR)/$$build_name" ]; then \
			echo -e "$(COLOR_YELLOW)Removing build artifacts for $$build_name...$(COLOR_RESET)"; \
			rm -rf "$(BUILD_DIR)/$$build_name"; \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo -e "$(COLOR_GREEN)✓ Cleaned $$build_name$(COLOR_RESET)"; \
			echo -e "$(COLOR_GREEN)Duration: $$duration seconds$(COLOR_RESET)"; \
		else \
			echo -e "$(COLOR_YELLOW)No build artifacts found for $$build_name$(COLOR_RESET)"; \
			echo "Note: Build names follow pattern: <family>-<machine>"; \
			echo "Example: raspberry-pi-raspberrypi5"; \
		fi; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make clean <family>-<machine>"; \
		echo "Example: make clean raspberry-pi-raspberrypi5"; \
		echo "Or use: make clean-all (removes everything)"; \
		exit 1; \
	fi

# ==============================================================================
# Artifact Collection
# ==============================================================================
.PHONY: collect-artifacts
collect-artifacts:
	@clear; args=($(filter-out $@,$(MAKECMDGOALS))); \
	if [ $${#args[@]} -eq 1 ]; then \
		build_name="$${args[0]}"; \
		board_build_dir="$(BUILD_DIR)/$$build_name"; \
		if [ ! -d "$$board_build_dir" ]; then \
			echo -e "$(COLOR_YELLOW)Error: Build directory not found: $$board_build_dir$(COLOR_RESET)"; \
			exit 1; \
		fi; \
		artifact_dir="$(ARTIFACTS_DIR)/$$build_name/$(TIMESTAMP)"; \
		mkdir -p "$$artifact_dir"/{images,sdk,licenses}; \
		echo -e "$(COLOR_BLUE)Collecting artifacts for $$build_name$(COLOR_RESET)"; \
		if [ -d "$$board_build_dir/tmp/deploy/images" ]; then \
			echo -e "$(COLOR_GREEN)Copying images...$(COLOR_RESET)"; \
			cp -r "$$board_build_dir/tmp/deploy/images"/* "$$artifact_dir/images/" 2>/dev/null || true; \
		fi; \
		if [ -d "$$board_build_dir/tmp/deploy/sdk" ]; then \
			echo -e "$(COLOR_GREEN)Copying SDK...$(COLOR_RESET)"; \
			cp -r "$$board_build_dir/tmp/deploy/sdk"/* "$$artifact_dir/sdk/" 2>/dev/null || true; \
		fi; \
		if [ -d "$$board_build_dir/tmp/deploy/licenses" ]; then \
			echo -e "$(COLOR_GREEN)Copying licenses...$(COLOR_RESET)"; \
			cp -r "$$board_build_dir/tmp/deploy/licenses"/* "$$artifact_dir/licenses/" 2>/dev/null || true; \
		fi; \
		echo "Build: $$build_name" > "$$artifact_dir/build-info.txt"; \
		echo "Timestamp: $(TIMESTAMP)" >> "$$artifact_dir/build-info.txt"; \
		echo "Build Directory: $$board_build_dir" >> "$$artifact_dir/build-info.txt"; \
		echo -e "$(COLOR_GREEN)✓ Artifacts collected to: $$artifact_dir$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_YELLOW)Error: Invalid arguments$(COLOR_RESET)"; \
		echo "Usage: make collect-artifacts <family>-<machine>"; \
		echo "Example: make collect-artifacts raspberry-pi-raspberrypi5"; \
		exit 1; \
	fi

# ==============================================================================
# Configuration Management
# ==============================================================================
.PHONY: config
config:
	@clear; echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Current Build Configuration:$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Build Variant:$(COLOR_RESET)"
	@echo ""
	@printf "$(COLOR_YELLOW)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BUILD_VARIANT =" "$(BUILD_VARIANT)"
	@echo -e "    $(COLOR_WHITE)debug$(COLOR_RESET)      - Debug build with symbols, extra logging"
	@echo -e "    $(COLOR_WHITE)release$(COLOR_RESET)    - Optimized production build (default)"
	@echo -e "    $(COLOR_WHITE)production$(COLOR_RESET) - Hardened production build with security features"
	@echo ""
	@echo -e "$(COLOR_BOLD)Performance Settings:$(COLOR_RESET)"
	@echo ""
	@printf "$(COLOR_GREEN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "BB_NUMBER_THREADS =" "$(BB_NUMBER_THREADS) (BitBake parallel tasks)"
	@printf "$(COLOR_GREEN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "PARALLEL_MAKE =" "$(PARALLEL_MAKE) (Make parallel jobs)"
	@printf "$(COLOR_GREEN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "RM_WORK =" "$(RM_WORK) (Remove work files: 1=yes, 0=no)"
	@echo ""
	@echo -e "$(COLOR_BOLD)Cache Directories:$(COLOR_RESET)"
	@echo ""
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "DL_DIR =" "$(SHARED_DL_DIR) (shared across all families)"
	@printf "$(COLOR_CYAN)%-25s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "SSTATE_BASE_DIR =" "$(SHARED_SSTATE_BASE_DIR) (family-arch-specific subdirs)"
	@echo -e "  $(COLOR_WHITE)SSTATE structure:$(COLOR_RESET)"
	@if [ -d "$(SHARED_SSTATE_BASE_DIR)" ]; then \
		for family_dir in $(SHARED_SSTATE_BASE_DIR)/*; do \
			if [ -d "$$family_dir" ]; then \
				family_name=$$(basename "$$family_dir"); \
				echo -e "    $(COLOR_BLUE)$$family_name$(COLOR_RESET): $(SHARED_SSTATE_BASE_DIR)/$$family_name"; \
			fi; \
		done; \
	else \
		echo "    $(COLOR_RED)(not yet initialized)$(COLOR_RESET)"; \
	fi
	@echo ""
	@echo -e "$(COLOR_BOLD)Usage Examples:$(COLOR_RESET)"
	@echo -e "  $(COLOR_WHITE)make build raspberry-pi raspberrypi5 core-image-base BUILD_VARIANT=debug$(COLOR_RESET)"
	@echo -e "  $(COLOR_WHITE)make build raspberry-pi raspberrypi5 core-image-base BB_NUMBER_THREADS=4$(COLOR_RESET)"
	@echo -e "  $(COLOR_WHITE)make build raspberry-pi raspberrypi5 core-image-base RM_WORK=0$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)To modify defaults:$(COLOR_RESET)"
	@echo -e "  $(COLOR_WHITE)Edit Makefile variables or set environment variables$(COLOR_RESET)"

# ==============================================================================
# Docker targets
# ==============================================================================
.PHONY: docker-build
docker-build:
	@clear; if docker images -q $(DOCKER_IMAGE) | grep -q .; then \
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
	@clear; $(MAKE) -C docker run

# ==============================================================================
# Catch-all target for board names (prevents "No rule to make target" errors)
# ==============================================================================
%:
	@:

.PHONY: docker-clean
docker-clean:
	@clear; $(MAKE) -C docker clean

.PHONY: docker
docker: docker-build