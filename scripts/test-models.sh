#!/bin/bash

# NVIDIA NIM Model Benchmark Script
# Tests latest code generation models from build.nvidia.com

set -e

API_KEY="${NIM_API_KEY}"
API_BASE="https://integrate.api.nvidia.com/v1"
OUTPUT_FILE="results.json"
HISTORY_FILE="../history.json"

PROMPT="Write a Python function that checks if a number is prime and returns True or False"

# Latest models from build.nvidia.com (as of April 2026)
MODELS=(
    "deepseek-ai/deepseek-v4-flash"
    "qwen/qwen3.5-122b-a10b"
    "nvidia/nemotron-3-super-120b-a12b"
    "google/gemma-4-31b-it"
    "mistralai/mistral-small-4-119b-2603"
    "meta/llama-3.3-70b-instruct"
    "meta/llama-3.1-405b-instruct"
    "meta/llama-3.1-70b-instruct"
    "meta/llama-3.1-8b-instruct"
    "microsoft/phi-4-mini-instruct"
    "mistralai/mixtral-8x22b-instruct-v0.1"
    "z-ai/glm-5.1"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RESULTS_JSON=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "prompt": "$PROMPT",
  "models": []
}
EOF
)

echo -e "${YELLOW}Starting NVIDIA NIM Model Benchmarks...${NC}"
echo "Timestamp: $TIMESTAMP"
echo "Testing ${#MODELS[@]} models..."
echo ""

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: NIM_API_KEY environment variable not set${NC}"
    exit 1
fi

RESULTS=()
for model in "${MODELS[@]}"; do
    echo -e "${YELLOW}Testing: $model${NC}"

    START_TIME=$(date +%s%N)

    RESPONSE=$(curl -s -X POST \
        "$API_BASE/chat/completions" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [
                {
                    \"role\": \"user\",
                    \"content\": \"$PROMPT\"
                }
            ],
            \"temperature\": 0.7,
            \"top_p\": 0.9,
            \"max_tokens\": 500,
            \"stream\": false
        }" 2>&1)

    END_TIME=$(date +%s%N)
    RESPONSE_TIME=$((($END_TIME - $START_TIME) / 1000000))

    ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null || echo "")
    if [ -n "$ERROR" ]; then
        echo -e "${RED}  ✗ Failed: $ERROR${NC}"
        MODEL_RESULT=$(cat <<EOF
{
  "model": "$model",
  "success": false,
  "error": "$ERROR",
  "responseTime": null,
  "tokensGenerated": null,
  "totalTokens": null,
  "response": null
}
EOF
)
    else
        CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null || echo "")
        TOKENS_GENERATED=$(echo "$RESPONSE" | jq -r '.usage.completion_tokens // 0' 2>/dev/null || echo "0")
        TOTAL_TOKENS=$(echo "$RESPONSE" | jq -r '.usage.total_tokens // 0' 2>/dev/null || echo "0")

        if [ -z "$CONTENT" ]; then
            ERROR="No content in response"
            echo -e "${RED}  ✗ Failed: $ERROR${NC}"
            MODEL_RESULT=$(cat <<EOF
{
  "model": "$model",
  "success": false,
  "error": "$ERROR",
  "responseTime": null,
  "tokensGenerated": null,
  "totalTokens": null,
  "response": null
}
EOF
)
        else
            echo -e "${GREEN}  ✓ Success (${RESPONSE_TIME}ms, $TOKENS_GENERATED tokens)${NC}"

            CONTENT_ESCAPED=$(echo "$CONTENT" | jq -Rs '.')

            MODEL_RESULT=$(cat <<EOF
{
  "model": "$model",
  "success": true,
  "responseTime": $RESPONSE_TIME,
  "tokensGenerated": $TOKENS_GENERATED,
  "totalTokens": $TOTAL_TOKENS,
  "response": $CONTENT_ESCAPED,
  "error": null
}
EOF
)
        fi
    fi

    RESULTS+=("$MODEL_RESULT")
    sleep 1
done

echo ""
echo -e "${YELLOW}Compiling results...${NC}"

MODELS_JSON=$(printf '%s\n' "${RESULTS[@]}" | jq -s '.')

FINAL_JSON=$(jq --argjson models "$MODELS_JSON" '.models = $models' <<< "$RESULTS_JSON")

# Compute summary
SUCCESS_COUNT=$(echo "$FINAL_JSON" | jq '[.models[] | select(.success == true)] | length')
TOTAL_COUNT=$(echo "$FINAL_JSON" | jq '.models | length')
FASTEST_MODEL=$(echo "$FINAL_JSON" | jq -r '[.models[] | select(.success == true)] | sort_by(.responseTime) | .[0].model // "N/A"')
FASTEST_TIME=$(echo "$FINAL_JSON" | jq '[.models[] | select(.success == true)] | sort_by(.responseTime) | .[0].responseTime // 0')

FINAL_JSON=$(jq --arg fastest "$FASTEST_MODEL" \
    --argjson fastestTime "$FASTEST_TIME" \
    --argjson successCount "$SUCCESS_COUNT" \
    --argjson totalModels "$TOTAL_COUNT" \
    '.summary = {successCount: $successCount, totalModels: $totalModels, fastestModel: $fastest, fastestTime: $fastestTime}' \
    <<< "$FINAL_JSON")

echo "$FINAL_JSON" | jq '.' > "$OUTPUT_FILE"

echo -e "${GREEN}Results saved to $OUTPUT_FILE${NC}"
echo "Summary: $SUCCESS_COUNT/$TOTAL_COUNT successful"

# Update history.json
if [ -f "$HISTORY_FILE" ]; then
    HISTORY=$(jq --argjson newrun "$FINAL_JSON" '.runs |= ([$newrun] + .) | .runs |= .[0:720]' "$HISTORY_FILE")
else
    HISTORY=$(jq -n --argjson newrun "$FINAL_JSON" '{runs: [$newrun]}')
fi

echo "$HISTORY" | jq '.' > "$HISTORY_FILE"
echo -e "${GREEN}History updated: $HISTORY_FILE${NC}"
