#!/usr/bin/env bash
set -euo pipefail

trap 'trap - INT; kill 0' INT

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <filepath> [count]" >&2
    exit 1
fi

filepath="$1"
count="${2:-1}"

if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
	echo "Error: <count> must be a positive integer." >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/../tasks"

SUCCESSFUL_TASKS=0
MAX_ATTEMPTS=20
CURRENT_ATTEMPT=0

while [[ $SUCCESSFUL_TASKS -lt $count && $CURRENT_ATTEMPT -lt $MAX_ATTEMPTS ]]; do
    echo "--- Generating a new task ($SUCCESSFUL_TASKS/$count) ---"
    trash "$SCRIPT_DIR/../harbor_gen_config.json" || true
    
    # Find existing tasks
    before_dirs=()
    while IFS= read -r dir; do
        before_dirs+=("$dir")
    done < <(find "$TASKS_DIR" -mindepth 1 -maxdepth 1 -type d)

    # Run task generation
    if ! "$SCRIPT_DIR/scripts/gen_tasks.sh" "$filepath"; then
        echo "Task generation failed. Retrying..."
        CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
        continue
    fi

    # Find the new task directory
    after_dirs=()
    while IFS= read -r dir; do
        after_dirs+=("$dir")
    done < <(find "$TASKS_DIR" -mindepth 1 -maxdepth 1 -type d)

    new_dir=""
    for dir in "${after_dirs[@]}"; do
        found=false
        for b_dir in "${before_dirs[@]}"; do
            if [[ "$dir" == "$b_dir" ]]; then
                found=true
                break
            fi
        done
        if ! $found; then
            new_dir="$dir"
            break
        fi
    done

    if [[ -z "$new_dir" ]]; then
        echo "Could not find a new task directory. Retrying..."
        CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
        continue
    fi

    echo "New task directory found: $new_dir"

    # Process and check the new task
    if "$SCRIPT_DIR/scripts/convert_to_local_docker_task.sh" "$new_dir" && \
       "$SCRIPT_DIR/scripts/check_initial_state.sh" "$new_dir"; then
        echo "--- Task successfully processed and checked: $new_dir ---"
        SUCCESSFUL_TASKS=$((SUCCESSFUL_TASKS + 1))
    else
        echo "--- Task failed processing or checking. Removing and retrying: $new_dir ---"
        trash "$new_dir"
    fi
    
    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
done

if [[ $SUCCESSFUL_TASKS -lt $count ]]; then
    echo "Failed to generate the required number of tasks after $MAX_ATTEMPTS attempts." >&2
    exit 1
fi

echo "Successfully generated $SUCCESSFUL_TASKS tasks."
