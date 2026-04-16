MODELS=(
    "google/gemini-3.1-pro"
    "google/gemini-3-flash"
    "openai/gpt-5.2-codex"
    "anthropic/claude-4-6-sonnet"
    "zai/glm-4.7"
)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/../tasks"
JOBS_DIR="$SCRIPT_DIR/../jobs"

MODEL_ARGS=()
for model in "${MODELS[@]}"; do
    MODEL_ARGS+=(--model "$model")
done

harbor run \
    "${MODEL_ARGS[@]}" \
    --agent-import-path agents.pochi:Pochi \
    --env docker \
    --path $TASKS_DIR \
    --jobs-dir $JOBS_DIR \
    --n-attempts 1 \
    --max-retries 0 \
    --n-concurrent 5 \
    --yes
