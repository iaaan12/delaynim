#!/bin/bash

# NVIDIA NIM Model Benchmark Script
# Tests top 10 code generation models from build.nvidia.com

set -e

# Configuration
API_KEY="${NIM_API_KEY}"
API_BASE="https://integrate.api.nvidia.com/v1"
OUTPUT_FILE="results.json"
TEMP_FILE="results_temp.json"

# Test prompt
PROMPT="Write a Python function that checks if a number is prime and returns True or False"

# Top 10 code generation models (as of 2024)
MODELS=(
    "nvidia/llama-3.1-nemotron-70b-instruct"
    "meta/llama-3.1-405b-instruct"
    "meta/llama-3.1-70b-instruct"
    "mistralai/mixtral-8x22b-instruct-v0.1"
    "mistralai/mixtral-8x7b-instruct-v0.1"
    "meta/llama-3-70b-instruct"
    "meta/llama-3-8b-instruct"
    "mistralai/mistral-large"
    "mistralai/mistral-medium"
    "mistralai/mistral-small"
)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize results array
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
echo "Prompt: $PROMPT"
echo "Testing ${#MODELS[@]} models..."
echo ""

# Check if API key is set
if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: NIM_API_KEY environment variable not set${NC}"
    exit 1
fi

# Test each model
RESULTS=()
for model in "${MODELS[@]}"; do
    echo -e "${YELLOW}Testing: $model${NC}"
    
    START_TIME=$(date +%s%N)
    
    # Make API call
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
    
    # Parse response
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
        # Extract data from response
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
            
            # Escape content for JSON
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
    
    # Rate limiting - small delay between requests
    sleep 1
done

echo ""
echo -e "${YELLOW}Compiling results...${NC}"

# Combine all results
MODELS_JSON=$(printf '%s\n' "${RESULTS[@]}" | jq -s '.')

# Create final JSON
FINAL_JSON=$(jq --argjson models "$MODELS_JSON" '.models = $models' <<< "$RESULTS_JSON")

# Write to file
echo "$FINAL_JSON" | jq '.' > "$OUTPUT_FILE"

echo -e "${GREEN}Results saved to $OUTPUT_FILE${NC}"
echo ""
echo "Summary:"
echo "--------"
SUCCESS_COUNT=$(echo "$FINAL_JSON" | jq '[.models[] | select(.success == true)] | length')
TOTAL_COUNT=$(echo "$FINAL_JSON" | jq '.models | length')
echo "Successful: $SUCCESS_COUNT/$TOTAL_COUNT"
echo "Timestamp: $(echo "$FINAL_JSON" | jq -r '.timestamp')"
