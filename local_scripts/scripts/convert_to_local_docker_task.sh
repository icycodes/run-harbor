#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/../../tasks"

find $TASKS_DIR -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    echo "=============================="
    echo "=============================="
    echo "=============================="
    echo "convert_to_local_docker_task: Processing $dir"
    echo "=============================="

    task_file="$dir/bootstrap/task.json"
    docker_file="$dir/environment/Dockerfile"
    instruction_file="$dir/instruction.md"
    test_sh_file="$dir/tests/test.sh"

    # Write instruction file
    if [[ ! -f "$task_file" ]]; then
        echo "Skip: no task.json"
        continue
    fi
    description=$(jq -er '.task_description // empty' "$task_file") || {
        echo "Skip: no task_description field in $task_file"
        continue
    }
    printf '%s\n' "$description" > "$instruction_file"


    # Override dockerfile
    if [[ ! -f "$docker_file" ]]; then
      echo "Skip: no Dockerfile"
      continue
    fi
    sed -i 's/^FROM ubuntu:24\.04$/FROM local-run-harbor-base/' "$docker_file"
    perl -0pi -e 's{RUN apt-get update -y && \\\n    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \\\n        curl ca-certificates git python3 python3-pip python3-pytest bash && \\\n    apt-get clean && \\\n    rm -rf /var/lib/apt/lists/\*\n?}{}g' "$docker_file"
    

    # Write test.sh file
    cat > "$test_sh_file" <<'EOF'
#!/bin/bash

# uvx is installed in the docker image, `source $HOME/.local/bin/env` to activate the environment.
source $HOME/.local/bin/env

# CTRF produces a standard test report in JSON format which is useful for logging.
uvx \
  --with pytest==8.4.1 \
  --with pytest-json-ctrf==0.3.5 \
  --with pytest-xprocess==1.0.2 \
  --with pochi-verifier==0.1.8 \
  pytest --ctrf /logs/verifier/ctrf.json /tests/test_final_state.py -rA

if [ $? -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi

EOF


    echo "✅ $dir done"
done
