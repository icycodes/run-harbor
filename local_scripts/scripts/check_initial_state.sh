#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <task_dir>" >&2
    exit 1
fi

dir="$1"

echo "=============================="
echo "=============================="
echo "=============================="
echo "check_initial_state: Processing $dir"
echo "=============================="

dockerfile="$dir/environment/Dockerfile"
test_file="$dir/bootstrap/test_initial_state.py"
task_toml_file="$dir/task.toml"

if [[ ! -f "$dockerfile" ]]; then
    echo "❌ no Dockerfile"
    exit 1
fi

if [[ ! -f "$test_file" ]]; then
    echo "❌ no test_initial_state.py"
    exit 1
fi

if [[ ! -f "$task_toml_file" ]]; then
    echo "❌ no task.toml"
    exit 1
fi

echo "Running bootstrap test"
if ! (
    dir_name="$(basename "$dir")"
    safe_name="$(printf '%s' "$dir_name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
    unique_suffix="$$-$(date +%s)"
    image_name="test-${safe_name}-${unique_suffix}"
    container_name="test-${safe_name}-${unique_suffix}"
    env_file="$(mktemp)"

    cleanup() {
        docker rm -f "$container_name" >/dev/null 2>&1 || true
        docker image rm "$image_name" >/dev/null 2>&1 || true
        rm -f "$env_file"
    }
    trap cleanup EXIT

    python3 - "$task_toml_file" "$env_file" <<'PY'
import os
import re
import sys
import tomllib

task_toml_path, env_file_path = sys.argv[1], sys.argv[2]

with open(task_toml_path, "rb") as handle:
    task_config = tomllib.load(handle)

environment = task_config.get("environment", {})
environment_env = environment.get("env", {})
pattern = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")

def resolve_value(value):
    if isinstance(value, str):
        return pattern.sub(lambda match: os.environ.get(match.group(1), ""), value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return ""
    return str(value)

with open(env_file_path, "w", encoding="utf-8") as handle:
    for key, value in environment_env.items():
        handle.write(f"{key}={resolve_value(value)}\n")
PY

    docker build -t "$image_name" -f "$dockerfile" "$dir"
    docker create \
        --name "$container_name" \
        --env-file "$env_file" \
        -w /workspace \
        "$image_name" \
        sh -lc 'mkdir -p /logs && python3 -c "import uuid; print(uuid.uuid4())" > /logs/trial_id && exec pytest bootstrap/test_initial_state.py' >/dev/null

    docker cp "$dir/." "$container_name:/workspace"
    docker start -a "$container_name"
); then
    echo "❌ $dir failed"
    exit 1
fi

echo "✅ $dir passed"
