#!/bin/bash

# Define colors with bold
BOLD_GRAY="\[\e[1;90m\]"
BOLD_RED="\[\e[1;31m\]"
BOLD_GREEN="\[\e[1;32m\]"
BOLD_YELLOW="\[\e[1;33m\]"
BOLD_BLUE="\[\e[1;34m\]"
BOLD_MAGENTA="\[\e[1;35m\]"
BOLD_CYAN="\[\e[1;36m\]"
BOLD_WHITE="\[\e[1;97m\]"
RESET="\[\e[0m\]"

# Function to get the current Python virtual environment
get_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        echo " ${BOLD_CYAN}($venv_name)${RESET}"
    fi
}

get_git_info() {
    # Check if we are in a git repo quickly
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    # 1. Get Branch Name
    local branch=$(git branch --show-current 2>/dev/null)
    # Handle detached HEAD state (shows commit hash if no branch name)
    if [[ -z "$branch" ]]; then
        branch=$(git rev-parse --short HEAD 2>/dev/null)
    fi

    # 2. Get Status ONLY ONCE using porcelain
    local git_status_output
    git_status_output=$(git status --porcelain 2>/dev/null)

    # 3. Calculate counts 
    # ^[MARD] matches lines starting with M, A, R, or D (Staged changes)
    local staged=$(echo "$git_status_output" | grep -c '^[MARD]')
    
    # ^.[MARD] matches lines where the second character is M, A, R, or D (Unstaged changes)
    local unstaged=$(echo "$git_status_output" | grep -c '^.[MARD]')
    
    # ^[?][?] matches lines starting with ?? (Untracked files)
    # This is the FIX for the "stray \ before ?" warning
    local untracked=$(echo "$git_status_output" | grep -c '^[?][?]')
    
    # 4. Determine overall clean/dirty symbol
    local status_symbol=""
    if [[ -z "$git_status_output" ]]; then
        status_symbol=" ${BOLD_GREEN}✔${RESET}"
    else
        status_symbol=" ${BOLD_RED}✘${RESET}"
    fi

    # 5. Build the status string
    local info=" ${BOLD_MAGENTA}$branch${RESET}$status_symbol"
    
    if [[ "$unstaged" -gt 0 ]]; then
        info+="${BOLD_YELLOW} $unstaged:!s${RESET}"
    fi
    if [[ "$staged" -gt 0 ]]; then
        info+="${BOLD_GREEN} $staged:s${RESET}"
    fi
    if [[ "$untracked" -gt 0 ]]; then
        info+="${BOLD_RED} $untracked:%${RESET}"
    fi

    echo "$info"
}

set_prompt() {
    # Store previous exit code immediately
    local exit_code=$?
    
    # Static elements
    local user="${BOLD_BLUE}$(whoami)${RESET}"
    local host="${BOLD_BLUE}$(hostname)${RESET}"
    local current_dir="${BOLD_YELLOW}\w${RESET}"
    local in="${BOLD_WHITE}┌ in${RESET}"
    local at="${BOLD_WHITE}@${RESET}"
    local line_start="${BOLD_WHITE}└${RESET}"
    
    # Color the dollar sign red if the last command failed
    local colon="${BOLD_WHITE}\$ ${RESET}"
    if [[ $exit_code -ne 0 ]]; then
        colon="${BOLD_RED}\$ ${RESET}"
    fi

    # Get dynamic sections
    local venv=$(get_venv)
    
    # We call the git function and capture the 'on' part if git returns anything
    local git_info=$(get_git_info)
    local on_block=""
    if [[ -n "$git_info" ]]; then
        on_block=" ${BOLD_WHITE}on${RESET}"
    fi

    # Construct PS1
    PS1="$in $current_dir$on_block$git_info$venv\n$line_start $user$at$host $colon"
}

# Append to PROMPT_COMMAND instead of overwriting
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }set_prompt"

# Trim long paths
PROMPT_DIRTRIM=3
