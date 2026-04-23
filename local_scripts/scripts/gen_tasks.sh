#!/usr/bin/env bash
set -uo pipefail

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

run_pochi() {
	POCHI_LOG=error pochi --max-steps 1000 <<EOF
Read and understand the ${filepath} file.
Use webSearch or webFetch to browse the documentation links provided in the plan.
Use the generate-harbor-tasks skill to generate a task.
There may already be some tasks in ./tasks; do not repeat any existing tasks.
EOF
}

failures=0
for ((run = 1; run <= count; run++)); do
	echo "=============================="
	echo "=============================="
	echo "=============================="
	echo "gen_tasks $run/$count"
	echo "=============================="
	if ! run_pochi; then
		echo "pochi failed on run $run" >&2
		failures=$((failures + 1))
	fi
done

echo "=============================="
echo "=============================="
echo "=============================="
if [ "$failures" -gt 0 ]; then
	echo "$failures runs failed" >&2
	exit 1
fi
