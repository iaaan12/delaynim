# NVIDIA NIM Model Benchmarking Dashboard

A static website that benchmarks NVIDIA NIM API models hourly using GitHub Actions.

## What is this?

This project automatically tests the top 10 code generation models available through NVIDIA's NIM API every hour. The test results are stored in `results.json` and displayed on the static website (`index.html`). Since it's all static, it can be hosted on GitHub Pages for free!

## Project Structure

```
├── index.html                           # Static website displaying results
├── results.json                         # Benchmark results (auto-updated hourly)
├── scripts/
│   └── test-models.sh                   # Bash script that runs the tests
└── .github/workflows/
    └── benchmark.yml                    # GitHub Action that runs tests hourly
```

## How it works

1. **GitHub Action** (`benchmark.yml`) runs on a cron schedule (every hour)
2. **Bash script** (`test-models.sh`) tests each model with the same prompt
3. **Results** are saved to `results.json` and committed back to the repo
4. **Static site** (`index.html`) loads `results.json` and displays the results beautifully

## Setup

### 1. Create a GitHub Repository

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/NIMStats.git
git branch -M main
git push -u origin main
```

### 2. Enable GitHub Pages

1. Go to your repository **Settings** → **Pages**
2. Under "Source", select **Deploy from a branch**
3. Select **main** branch and **/ (root)** folder
4. Click Save

### 3. Add Your NVIDIA NIM API Key

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `NIM_API_KEY`
4. Value: Your NVIDIA NIM API key (get it from [build.nvidia.com](https://build.nvidia.com))
5. Click **Add secret**

### 4. Test It Out

1. Go to **Actions** tab in your repository
2. Select **Test NVIDIA NIM Models** workflow
3. Click **Run workflow**
4. Wait for it to complete (should take a few minutes)
5. Check your GitHub Pages site at `https://YOUR_USERNAME.github.io/NIMStats/`

## Customization

### Change the test prompt
Edit `scripts/test-models.sh` and modify the `PROMPT` variable:
```bash
PROMPT="Your custom prompt here"
```

### Change the models being tested
Edit `scripts/test-models.sh` and modify the `MODELS` array:
```bash
MODELS=(
    "model/name-1"
    "model/name-2"
    # ... etc
)
```

### Change the test schedule
Edit `.github/workflows/benchmark.yml` and modify the cron expression:
```yaml
cron: '0 * * * *'  # Every hour at the top of the hour
# Examples:
# '0 */6 * * *'    # Every 6 hours
# '0 0 * * *'      # Daily at midnight
# '*/30 * * * *'   # Every 30 minutes
```

## Models Being Tested

The script tests these 10 popular code generation models:
- nvidia/llama-3.1-nemotron-70b-instruct
- meta/llama-3.1-405b-instruct
- meta/llama-3.1-70b-instruct
- mistralai/mixtral-8x22b-instruct-v0.1
- mistralai/mixtral-8x7b-instruct-v0.1
- meta/llama-3-70b-instruct
- meta/llama-3-8b-instruct
- mistralai/mistral-large
- mistralai/mistral-medium
- mistralai/mistral-small

## Features

✨ **Dashboard Features:**
- Real-time results display
- Sort by model name, response time, or token count
- View full response text for each model
- Success/error indicators
- Response times in seconds
- Token usage tracking (generated + total)
- Auto-refreshes every 30 seconds
- Beautiful dark theme
- Mobile responsive

## Troubleshooting

### Results aren't updating
1. Check that `NIM_API_KEY` secret is properly set
2. Go to Actions tab and check workflow logs
3. Make sure you have GitHub Pages enabled

### "No results available yet"
1. The action may still be running - wait a few minutes
2. Manually trigger the workflow from the Actions tab
3. Check the workflow logs for errors

### API Key errors
- Make sure your API key is valid at [build.nvidia.com](https://build.nvidia.com)
- Verify the secret is named exactly `NIM_API_KEY`
- Check that you have API quota remaining

## API Endpoint Used

- **Base URL**: `https://integrate.api.nvidia.com/v1`
- **Endpoint**: `POST /chat/completions`
- **Format**: OpenAI-compatible API

## License

MIT
