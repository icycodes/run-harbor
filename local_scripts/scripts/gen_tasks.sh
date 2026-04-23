#!/usr/bin/env bash
set -uo pipefail

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <filepath>" >&2
	exit 1
fi

filepath="$1"

run_pochi() {
	POCHI_LOG=error pochi --max-steps 1000 <<EOF
Read and understand the ${filepath} file.
Use webSearch or webFetch to browse the documentation links provided in the plan.
Use the generate-harbor-tasks skill to generate a task.
There may already be some tasks in ./tasks; do not repeat any existing tasks.
EOF
}

echo "=============================="
echo "=============================="
echo "=============================="
echo "gen_tasks"
echo "=============================="
if ! run_pochi; then
	echo "pochi failed" >&2
	exit 1
fi
