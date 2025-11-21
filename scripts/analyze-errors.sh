#!/bin/bash
# ==============================================================================
# Error Analysis Script
# Analyzes build logs and suggests fixes
# ==============================================================================

set -e

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_CYAN="\033[36m"
COLOR_BLUE="\033[34m"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <family-machine>"
    echo "Example: $0 raspberry-pi-raspberrypi5"
    exit 1
fi

BUILD_NAME="$1"
BUILD_DIR="build/$BUILD_NAME"
LOG_DIR="$BUILD_DIR/tmp/log"

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${COLOR_RED}Error: Build directory not found: $BUILD_DIR${COLOR_RESET}"
    exit 1
fi

echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo -e "${COLOR_BLUE}  Error Analysis for: $BUILD_NAME${COLOR_RESET}"
echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo ""

# Check if logs exist
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${COLOR_YELLOW}No log directory found. Build may not have started.${COLOR_RESET}"
    exit 0
fi

# Find error logs
echo -e "${COLOR_CYAN}Searching for errors...${COLOR_RESET}"
echo ""

ERRORS_FOUND=0

# Check cooker logs for general errors
if [ -d "$LOG_DIR/cooker" ]; then
    COOKER_ERRORS=$(grep -r "ERROR:" "$LOG_DIR/cooker" 2>/dev/null | head -20)
    if [ -n "$COOKER_ERRORS" ]; then
        echo -e "${COLOR_RED}BitBake Errors:${COLOR_RESET}"
        echo "$COOKER_ERRORS" | while read line; do
            echo -e "  ${COLOR_YELLOW}•${COLOR_RESET} $line"
        done
        echo ""
        ERRORS_FOUND=1
    fi
fi

# Analyze common error patterns and suggest fixes
echo -e "${COLOR_CYAN}Analyzing error patterns...${COLOR_RESET}"
echo ""

# Pattern: Fetch failures
if grep -rq "Fetcher failure" "$LOG_DIR" 2>/dev/null || grep -rq "Unable to fetch" "$LOG_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}[Fetch Failure Detected]${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Possible causes:${COLOR_RESET}"
    echo "  1. Network connectivity issue"
    echo "  2. Repository moved or deleted"
    echo "  3. Authentication required"
    echo ""
    echo -e "${COLOR_GREEN}Suggested fixes:${COLOR_RESET}"
    echo "  • Check internet connection: ping github.com"
    echo "  • Verify proxy settings if behind firewall"
    echo "  • Try again (temporary network glitch)"
    echo "  • Update repository URLs in board configuration"
    echo ""
    ERRORS_FOUND=1
fi

# Pattern: Disk space
if grep -rq "No space left on device" "$LOG_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}[Disk Space Issue Detected]${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Out of disk space!${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Suggested fixes:${COLOR_RESET}"
    echo "  • Check available space: df -h"
    echo "  • Clean old builds: make clean-all"
    echo "  • Clean caches: make clean-shared (will slow next build)"
    echo "  • Remove unnecessary files from your system"
    echo ""
    ERRORS_FOUND=1
fi

# Pattern: Missing dependencies
if grep -rq "No provider" "$LOG_DIR" 2>/dev/null || grep -rq "Nothing PROVIDES" "$LOG_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}[Missing Dependency Detected]${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}A required package or recipe is missing${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Suggested fixes:${COLOR_RESET}"
    echo "  • Check if required layers are included in configuration"
    echo "  • Verify recipe names in IMAGE_INSTALL"
    echo "  • Check for typos in package names"
    echo "  • Consult recipe documentation"
    echo ""
    ERRORS_FOUND=1
fi

# Pattern: Compilation failures
if grep -rq "ERROR: Task.*failed" "$LOG_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}[Compilation Failure Detected]${COLOR_RESET}"
    
    # Find failed tasks
    FAILED_TASKS=$(grep -r "ERROR: Task.*failed" "$LOG_DIR" 2>/dev/null | grep -oP 'Task.*failed' | sort -u | head -5)
    
    echo -e "${COLOR_YELLOW}Failed tasks:${COLOR_RESET}"
    echo "$FAILED_TASKS" | while read task; do
        echo -e "  ${COLOR_YELLOW}•${COLOR_RESET} $task"
    done
    echo ""
    
    echo -e "${COLOR_GREEN}Suggested fixes:${COLOR_RESET}"
    echo "  • Check task logs in: $BUILD_DIR/tmp/work/*/*/temp/"
    echo "  • Look for compile errors (missing headers, incompatible code)"
    echo "  • Try cleaning the failing package: bitbake -c clean <package>"
    echo "  • Search for known issues with the package version"
    echo ""
    ERRORS_FOUND=1
fi

# Pattern: Configuration errors
if grep -rq "ParseError" "$LOG_DIR" 2>/dev/null || grep -rq "ExpansionError" "$LOG_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}[Configuration Error Detected]${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Issue in recipe or configuration syntax${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Suggested fixes:${COLOR_RESET}"
    echo "  • Check for syntax errors in custom recipes"
    echo "  • Verify variable expansions"
    echo "  • Review recent changes to local.conf or layer configs"
    echo "  • Validate YAML syntax in KAS configuration"
    echo ""
    ERRORS_FOUND=1
fi

# Pattern: Checksum mismatch
if grep -rq "Checksum mismatch" "$LOG_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}[Checksum Mismatch Detected]${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Downloaded file doesn't match expected checksum${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Suggested fixes:${COLOR_RESET}"
    echo "  • Upstream tarball may have been updated"
    echo "  • Clean downloads: rm shared/downloads/<package>*"
    echo "  • Update checksums in recipe (SRC_URI[sha256sum])"
    echo "  • Verify download source is trusted"
    echo ""
    ERRORS_FOUND=1
fi

# Check for recent log files with errors
echo -e "${COLOR_CYAN}Recent error logs:${COLOR_RESET}"
echo ""

ERROR_LOGS=$(find "$LOG_DIR" -name "*.log" -type f -mmin -60 -exec grep -l "ERROR" {} \; 2>/dev/null | head -10)

if [ -n "$ERROR_LOGS" ]; then
    echo "$ERROR_LOGS" | while read logfile; do
        rel_path=$(echo "$logfile" | sed "s|$BUILD_DIR/||")
        echo -e "  ${COLOR_YELLOW}•${COLOR_RESET} $rel_path"
    done
    echo ""
    echo -e "${COLOR_CYAN}To view a specific log:${COLOR_RESET}"
    echo "  less $BUILD_DIR/tmp/log/..."
else
    echo "  No recent error logs found"
    echo ""
fi

# Summary
echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"

if [ $ERRORS_FOUND -eq 0 ]; then
    echo -e "${COLOR_GREEN}No obvious error patterns detected.${COLOR_RESET}"
    echo ""
    echo "The build may have failed due to a complex issue."
    echo "Review the complete logs in: $LOG_DIR"
else
    echo -e "${COLOR_YELLOW}Review the suggestions above and try rebuilding.${COLOR_RESET}"
    echo ""
    echo "To retry the build:"
    echo "  make build <family> <machine> <target>"
fi

echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
