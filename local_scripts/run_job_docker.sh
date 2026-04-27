MODELS=(
    "google/gemini-3.1-pro"
    "google/gemini-3-flash"
    "openai/gpt-5.2-codex"
    "anthropic/claude-4-6-sonnet"
    "zai/glm-4.7"
)

# Default to 1 model if no argument is provided
NUM_MODELS_ARG=${1:-1}

if [ "$NUM_MODELS_ARG" = "1" ] && [ -z "$1" ]; then
    echo "Hint: No model count specified, defaulting to 1. Use 'all' or a number to specify how many models to run."
fi

# Validate input
if [[ "$NUM_MODELS_ARG" != "all" ]] && ! [[ "$NUM_MODELS_ARG" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid input. Please provide 'all' or a number."
    exit 1
fi

NUM_AVAILABLE_MODELS=${#MODELS[@]}
if [[ "$NUM_MODELS_ARG" != "all" ]] && ( [ "$NUM_MODELS_ARG" -lt 1 ] || [ "$NUM_MODELS_ARG" -gt "$NUM_AVAILABLE_MODELS" ] ); then
    echo "Error: Invalid number of models. Please choose a number between 1 and $NUM_AVAILABLE_MODELS."
    exit 1
fi

# Determine which models to use
if [[ "$NUM_MODELS_ARG" == "all" ]]; then
    MODELS_TO_RUN=("${MODELS[@]}")
else
    MODELS_TO_RUN=("${MODELS[@]:0:$NUM_MODELS_ARG}")
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/../tasks"
JOBS_DIR="$SCRIPT_DIR/../jobs"

MODEL_ARGS=()
for model in "${MODELS_TO_RUN[@]}"; do
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
    --n-concurrent 1 \
    --artifact /home/user \
    --yes

python3 "$SCRIPT_DIR/pyscripts/check_key_leak.py"
