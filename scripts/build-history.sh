#!/bin/bash
# ==============================================================================
# Build History Tracking System
# Records build attempts, duration, and outcomes
# ==============================================================================

HISTORY_DIR=".build-history"
HISTORY_DB="$HISTORY_DIR/builds.log"

# Ensure history directory exists
mkdir -p "$HISTORY_DIR"

# Colors
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_CYAN="\033[36m"

# ==============================================================================
# Functions
# ==============================================================================

# Record build start
record_build_start() {
    local family="$1"
    local machine="$2"
    local target="$3"
    local variant="${4:-release}"
    local timestamp=$(date +%s)
    local datetime=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create build record
    echo "$timestamp|START|$family|$machine|$target|$variant|$datetime" >> "$HISTORY_DB"
    
    # Create checkpoint file
    local build_name="$family-$machine"
    echo "$timestamp" > "$HISTORY_DIR/$build_name.checkpoint"
    echo "STARTED" >> "$HISTORY_DIR/$build_name.checkpoint"
    echo "$target" >> "$HISTORY_DIR/$build_name.checkpoint"
    echo "$variant" >> "$HISTORY_DIR/$build_name.checkpoint"
}

# Record build completion
record_build_end() {
    local family="$1"
    local machine="$2"
    local target="$3"
    local status="$4"  # SUCCESS or FAILED
    local start_time="$5"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local datetime=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Record to database
    echo "$end_time|$status|$family|$machine|$target|$duration|$datetime" >> "$HISTORY_DB"
    
    # Update checkpoint file
    local build_name="$family-$machine"
    if [ -f "$HISTORY_DIR/$build_name.checkpoint" ]; then
        echo "$status" >> "$HISTORY_DIR/$build_name.checkpoint"
        echo "$end_time" >> "$HISTORY_DIR/$build_name.checkpoint"
        echo "$duration" >> "$HISTORY_DIR/$build_name.checkpoint"
    fi
}

# Get last build info
get_last_build() {
    local family="$1"
    local machine="$2"
    local build_name="$family-$machine"
    
    if [ -f "$HISTORY_DIR/$build_name.checkpoint" ]; then
        cat "$HISTORY_DIR/$build_name.checkpoint"
    fi
}

# Check if build can be resumed
can_resume() {
    local family="$1"
    local machine="$2"
    local build_name="$family-$machine"
    
    if [ -f "$HISTORY_DIR/$build_name.checkpoint" ]; then
        # Check if last build failed
        if grep -q "FAILED" "$HISTORY_DIR/$build_name.checkpoint"; then
            # Check if build directory exists
            if [ -d "build/$build_name" ]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Show build history
show_history() {
    if [ ! -f "$HISTORY_DB" ]; then
        echo -e "${COLOR_YELLOW}No build history found${COLOR_RESET}"
        return
    fi
    
    echo -e "${COLOR_CYAN}Build History (Last 20 builds):${COLOR_RESET}"
    echo ""
    printf "%-20s %-20s %-30s %-15s %-10s %s\n" "DATE" "FAMILY-MACHINE" "TARGET" "VARIANT" "STATUS" "DURATION"
    echo "────────────────────────────────────────────────────────────────────────────────────────────────────"
    
    # Parse and display history (show last 20)
    tail -n 40 "$HISTORY_DB" | while IFS='|' read -r timestamp event family machine target variant_or_duration datetime_or_extra rest; do
        if [ "$event" = "START" ]; then
            start_time="$timestamp"
            start_datetime="$datetime_or_extra"
            build_key="$family-$machine-$target"
            # Store start time for pairing with end
            echo "$start_time|$start_datetime|$family|$machine|$target|$variant_or_duration" > "/tmp/build_start_$$"
        elif [ "$event" = "SUCCESS" ] || [ "$event" = "FAILED" ]; then
            # This is an end record
            if [ -f "/tmp/build_start_$$" ]; then
                read start_time start_datetime fam mach targ var < <(cat "/tmp/build_start_$$" | tr '|' ' ')
                
                if [ "$fam" = "$family" ] && [ "$mach" = "$machine" ] && [ "$targ" = "$target" ]; then
                    duration_sec="$variant_or_duration"
                    duration_min=$((duration_sec / 60))
                    duration_hr=$((duration_min / 60))
                    duration_min=$((duration_min % 60))
                    
                    if [ "$event" = "SUCCESS" ]; then
                        status="${COLOR_GREEN}SUCCESS${COLOR_RESET}"
                    else
                        status="${COLOR_RED}FAILED${COLOR_RESET}"
                    fi
                    
                    if [ $duration_hr -gt 0 ]; then
                        duration_str="${duration_hr}h ${duration_min}m"
                    else
                        duration_str="${duration_min}m"
                    fi
                    
                    printf "%-20s %-20s %-30s %-15s %-10s %s\n" \
                        "$start_datetime" \
                        "$fam-$mach" \
                        "$targ" \
                        "$var" \
                        "$(echo -e $status)" \
                        "$duration_str"
                    
                    rm -f "/tmp/build_start_$$"
                fi
            fi
        fi
    done | tail -n 20
    
    # Cleanup
    rm -f "/tmp/build_start_$$"
    echo ""
}

# Show statistics
show_stats() {
    if [ ! -f "$HISTORY_DB" ]; then
        echo -e "${COLOR_YELLOW}No build history found${COLOR_RESET}"
        return
    fi
    
    echo -e "${COLOR_CYAN}Build Statistics:${COLOR_RESET}"
    echo ""
    
    # Count builds
    local total=$(grep -c "|SUCCESS\|FAILED|" "$HISTORY_DB" || echo 0)
    local success=$(grep -c "|SUCCESS|" "$HISTORY_DB" || echo 0)
    local failed=$(grep -c "|FAILED|" "$HISTORY_DB" || echo 0)
    
    if [ $total -gt 0 ]; then
        local success_rate=$((success * 100 / total))
        
        echo "Total Builds:    $total"
        echo "Successful:      $success (${success_rate}%)"
        echo "Failed:          $failed"
        echo ""
        
        # Average duration for successful builds
        local total_duration=0
        local count=0
        while IFS='|' read -r timestamp event family machine target duration datetime; do
            if [ "$event" = "SUCCESS" ]; then
                total_duration=$((total_duration + duration))
                ((count++))
            fi
        done < "$HISTORY_DB"
        
        if [ $count -gt 0 ]; then
            local avg_duration=$((total_duration / count))
            local avg_min=$((avg_duration / 60))
            local avg_hr=$((avg_min / 60))
            local avg_min=$((avg_min % 60))
            
            echo "Average Build Time (success): ${avg_hr}h ${avg_min}m"
        fi
    else
        echo "No builds recorded yet"
    fi
    echo ""
}

# Main command handler
case "${1:-}" in
    start)
        record_build_start "$2" "$3" "$4" "$5"
        ;;
    end)
        record_build_end "$2" "$3" "$4" "$5" "$6"
        ;;
    show)
        show_history
        ;;
    stats)
        show_stats
        ;;
    can-resume)
        can_resume "$2" "$3"
        ;;
    get-last)
        get_last_build "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {start|end|show|stats|can-resume|get-last} [args...]"
        exit 1
        ;;
esac
