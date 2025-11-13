#!/bin/bash

# Bash completion for the KAS Board Building Makefile

# Function to get list of available boards
_get_boards() {
    local boards_dir="boards"
    local boards=()
    if [ -d "$boards_dir" ]; then
        while IFS= read -r -d '' file; do
            board=$(basename "$file" .yml)
            boards+=("$board")
        done < <(find "$boards_dir" -name "*.yml" -print0)
    fi
    echo "${boards[@]}"
}

# Completion function for make
_make_completion() {
    local cur prev words cword
    _init_completion || return

    local targets_with_boards="build dry-run sdk esdk fetch shell clean copy-artifacts"

    # Check if the previous word is a target that takes a board
    if [[ " $targets_with_boards " =~ " $prev " ]]; then
        # Complete with board names
        local boards
        mapfile -t boards < <(_get_boards)
        COMPREPLY=( $(compgen -W "${boards[*]}" -- "$cur") )
        return
    fi

    # For other cases, complete with make targets
    local targets="build dry-run dry-run-all sdk esdk fetch shell copy-artifacts list info help clean clean-all docker-build docker-run docker-clean docker"
    COMPREPLY=( $(compgen -W "$targets" -- "$cur") )
}

# Register the completion function for make
complete -F _make_completion make