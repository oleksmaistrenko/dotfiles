#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory from the JSON input
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Get just the directory name (basename)
dir_name=$(basename "$current_dir")

# Get git branch (skip locks for reliability)
git_branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || "detached")
fi

# Get session ID for token tracking
session_id=$(echo "$input" | jq -r '.session_id')

# Try to get token usage from transcript if available
transcript_path=$(echo "$input" | jq -r '.transcript_path')
tokens_info=""
if [ -f "$transcript_path" ] && [ -n "$transcript_path" ] && [ "$transcript_path" != "null" ]; then
    # Extract token usage from the transcript file
    input_tokens=$(grep -o '"input_tokens":[0-9]*' "$transcript_path" | tail -1 | cut -d: -f2)
    output_tokens=$(grep -o '"output_tokens":[0-9]*' "$transcript_path" | tail -1 | cut -d: -f2)
    
    if [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
        total_tokens=$((input_tokens + output_tokens))
        tokens_info=" | ${total_tokens} tokens"
    fi
fi

# Build the status line
status_line="🐼 $dir_name"

if [ -n "$git_branch" ]; then
    status_line="$status_line | $git_branch"
fi

status_line="$status_line$tokens_info"

printf "%s" "$status_line"