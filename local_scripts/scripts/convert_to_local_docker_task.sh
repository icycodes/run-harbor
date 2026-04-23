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
echo "convert_to_local_docker_task: Processing $dir"
echo "=============================="

task_file="$dir/bootstrap/task.json"
docker_file="$dir/environment/Dockerfile"
instruction_file="$dir/instruction.md"
test_sh_file="$dir/tests/test.sh"

# Write instruction file
if [[ ! -f "$task_file" ]]; then
    echo "❌: no task.json"
    exit 1
fi
description=$(jq -er '.task_description // empty' "$task_file") || {
    echo "❌: no task_description field in $task_file"
    exit 1
}
printf '%s\n' "$description" > "$instruction_file"


# Override dockerfile
if [[ ! -f "$docker_file" ]]; then
    echo "❌: no Dockerfile"
    exit 1
fi
if ! grep -q '^FROM ubuntu:24\.04$' "$docker_file"; then
    echo "❌: Dockerfile does not contain 'FROM ubuntu:24.04'"
    exit 1
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
