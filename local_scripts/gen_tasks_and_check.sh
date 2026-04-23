#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <filepath> [count]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Running gen_tasks.sh"
"$SCRIPT_DIR/scripts/gen_tasks.sh" "$@"

echo "Running convert_to_local_docker_task.sh"
"$SCRIPT_DIR/scripts/convert_to_local_docker_task.sh"

echo "Running check_initial_state.sh"
"$SCRIPT_DIR/scripts/check_initial_state.sh"
