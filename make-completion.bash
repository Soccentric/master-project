#!/bin/bash

# Bash completion for the KAS Board Building Makefile

# Function to get list of available board families
_get_families() {
    echo "raspberry-pi xilinx-zynq nvidia-jetson nxp-imx texas-instruments"
}

# Function to get list of supported machines for a family
_get_machines() {
    local family="$1"
    local machines_file="boards/$family/.machines"
    if [ -f "$machines_file" ]; then
        grep -v "^#" "$machines_file" | grep -v "^$"
    fi
}

# Function to get list of supported targets for a family
_get_targets() {
    local family="$1"
    local targets_file="boards/$family/.targets"
    if [ -f "$targets_file" ]; then
        grep -v "^#" "$targets_file" | grep -v "^$"
    fi
}

# Function to get list of existing build directories for clean and collect-artifacts commands
_get_build_dirs() {
    local build_dir="build"
    if [ -d "$build_dir" ]; then
        find "$build_dir" -maxdepth 1 -type d ! -name "build" -exec basename {} \;
    fi
}

# Completion function for make
_make_completion() {
    local cur prev words cword
    _init_completion || return

    # Targets that require: <family> <machine> <target>
    local targets_with_family_machine_target="build sdk esdk shell"
    # Targets that require: <family-machine> (build directory name)
    local targets_with_build_name="clean collect-artifacts"
    # Targets that require: <family> (family name only)
    local targets_with_family="clean-sstate-family"
    # Targets with no arguments
    local standalone_targets="list info help clean-all clean-shared version prerequisites docker-build docker-run docker-clean setup-completion config all"

    # Determine position in command and identify the make target
    local pos=0
    local target=""
    for ((i=1; i < cword; i++)); do
        local word="${words[i]}"
        # Skip variable assignments (e.g., BUILD_VARIANT=debug)
        if [[ "$word" == *=* ]]; then
            continue
        fi
        # Skip make options
        if [[ "$word" == -* ]]; then
            continue
        fi
        if [ $pos -eq 0 ]; then
            target="$word"
            pos=1
        else
            pos=$((pos + 1))
        fi
    done

    # If we're completing after a target that takes family, machine, target
    if [[ " $targets_with_family_machine_target " =~ " $target " ]]; then
        case $pos in
            1)
                # Complete with family names
                COMPREPLY=( $(compgen -W "$(_get_families)" -- "$cur") )
                return
                ;;
            2)
                # Complete with machine names for the selected family
                local family="${words[cword-1]}"
                local machines=$(_get_machines "$family")
                COMPREPLY=( $(compgen -W "$machines" -- "$cur") )
                return
                ;;
            3)
                # Complete with target names for the selected family
                # Find the family (it's 2 positions back)
                local family=""
                local arg_count=0
                for ((i=1; i < cword; i++)); do
                    local word="${words[i]}"
                    if [[ "$word" != *=* ]] && [[ "$word" != -* ]]; then
                        arg_count=$((arg_count + 1))
                        if [ $arg_count -eq 2 ]; then
                            family="$word"
                            break
                        fi
                    fi
                done
                if [ -n "$family" ]; then
                    local targets=$(_get_targets "$family")
                    COMPREPLY=( $(compgen -W "$targets" -- "$cur") )
                fi
                return
                ;;
        esac
    fi

    # If we're completing after clean or collect-artifacts command
    if [[ " $targets_with_build_name " =~ " $target " ]] && [ $pos -eq 1 ]; then
        # Complete with existing build directory names
        local builds=$(_get_build_dirs)
        COMPREPLY=( $(compgen -W "$builds" -- "$cur") )
        return
    fi

    # If we're completing after clean-sstate-family command
    if [[ " $targets_with_family " =~ " $target " ]] && [ $pos -eq 1 ]; then
        # Complete with family names
        COMPREPLY=( $(compgen -W "$(_get_families)" -- "$cur") )
        return
    fi

    # Complete variable assignments
    if [[ "$cur" == *=* ]]; then
        local var="${cur%%=*}"
        local val="${cur#*=}"
        case "$var" in
            BUILD_VARIANT)
                COMPREPLY=( $(compgen -W "debug release production" -P "${var}=" -- "$val") )
                return
                ;;
            BB_NUMBER_THREADS|PARALLEL_MAKE)
                # Could suggest CPU counts, but just allow freeform
                return
                ;;
            RM_WORK)
                COMPREPLY=( $(compgen -W "0 1" -P "${var}=" -- "$val") )
                return
                ;;
        esac
    fi

    # If current word starts with a variable name, complete it
    if [[ "$cur" == BUILD* ]] || [[ "$cur" == BB* ]] || [[ "$cur" == PARALLEL* ]] || [[ "$cur" == RM* ]]; then
        local vars="BUILD_VARIANT= BB_NUMBER_THREADS= PARALLEL_MAKE= RM_WORK="
        COMPREPLY=( $(compgen -W "$vars" -- "$cur") )
        return
    fi

    # For other cases, complete with all make targets
    local all_targets="$targets_with_family_machine_target $targets_with_build_name $targets_with_family $standalone_targets"
    COMPREPLY=( $(compgen -W "$all_targets" -- "$cur") )
}

# Register the completion function for make
complete -F _make_completion make
