# NIMStats — NVIDIA NIM Benchmark Dashboard

[![GitHub Actions](https://github.com/MauroDruwel/NIMStats/workflows/Benchmark%20NVIDIA%20NIM%20Models/badge.svg)](https://github.com/MauroDruwel/NIMStats/actions)
[![GitHub Pages](https://img.shields.io/badge/view-live%20dashboard-brightgreen)](https://maurodruwel.github.io/NIMStats/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Community Driven](https://img.shields.io/badge/community-driven-orange.svg)](CONTRIBUTING.md)

**Real-time performance benchmarking of NVIDIA NIM API models with automated hourly testing and comprehensive historical analytics.**

> Track how different LLMs perform under identical conditions. Understand latency, throughput, and reliability across your favorite models on NVIDIA's NIM API.

## Features

✨ **Automated Benchmarking**
- Hourly automated testing via GitHub Actions (completely free)
- Identical prompts across all models for fair comparison
- Real-time results updated every hour
- No infrastructure costs — runs on GitHub's free runners

📊 **Professional Dashboard**
- **Live KPI Cards** — Total runs, success rates, fastest responses, best throughput
- **Performance Charts** — Response time comparison, success rate trends, historical analysis
- **Results Table** — Sort by speed, token generation, or model name
- **Run History** — Complete audit trail of all benchmark runs
- **Response Viewer** — Inspect full model outputs with syntax highlighting

🔍 **Deep Insights**
- Track model performance over time
- Identify regressions and improvements
- Compare token generation rates (tokens/second)
- Monitor API reliability and uptime
- Export data for further analysis

⚡ **Easy Setup**
- Static website — deploy anywhere (GitHub Pages included)
- No backend required — everything is client-side
- Works offline — all data embedded in JSON
- Responsive design — works on mobile, tablet, desktop

## Quick Start

### 1. Clone & Setup

```bash
git clone https://github.com/MauroDruwel/NIMStats.git
cd NIMStats
```

### 2. Get Your NIM API Key

1. Go to [build.nvidia.com](https://build.nvidia.com)
2. Sign up (free, no credit card required)
3. Navigate to your API key in the account settings
4. Copy your API key

### 3. Add to GitHub Secrets

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `NIM_API_KEY`
4. Value: Your API key from build.nvidia.com
5. Click **Add secret**

### 4. Enable GitHub Pages

1. Go to **Settings** → **Pages**
2. Under "Source", select **Deploy from a branch**
3. Select **main** branch and **/ (root)** folder
4. Click **Save**

### 5. Trigger Your First Run

1. Go to **Actions** tab
2. Select **Benchmark NVIDIA NIM Models**
3. Click **Run workflow**
4. Wait 2-5 minutes for completion
5. Visit your site: `https://YOUR_USERNAME.github.io/NIMStats/`

## Current Models

The benchmark tests these latest NVIDIA NIM models:

| Model | Type | Size | Use Case |
|-------|------|------|----------|
| `deepseek-ai/deepseek-v4-flash` | MoE | 284B | Fast coding & reasoning |
| `qwen/qwen3.5-122b-a10b` | MoE | 122B | Excellent code generation |
| `nvidia/nemotron-3-super-120b-a12b` | MoE | 120B | NVIDIA's flagship |
| `google/gemma-4-31b-it` | Dense | 31B | High-quality reasoning |
| `mistralai/mistral-small-4-119b-2603` | MoE | 119B | Efficient hybrid |
| `meta/llama-3.3-70b-instruct` | Dense | 70B | Latest Llama |
| `meta/llama-3.1-405b-instruct` | Dense | 405B | Largest Llama |
| `meta/llama-3.1-70b-instruct` | Dense | 70B | Balanced performance |
| `meta/llama-3.1-8b-instruct` | Dense | 8B | Small & fast |
| `microsoft/phi-4-mini-instruct` | Dense | ~13B | Efficient inference |
| `mistralai/mixtral-8x22b-instruct-v0.1` | MoE | 141B | Classic Mixtral |
| `z-ai/glm-5.1` | Dense | 1T* | Agentic workflows |

*GLM-5.1 parameters include all tokens processed, not just active parameters.

## Architecture

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│ GitHub Actions Workflow (Hourly)                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Checkout repository                                     │
│  2. Run test-models.sh (tests all 12 models)                │
│  3. Update history.json (append new run)                    │
│  4. Commit & push to repo                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ GitHub Pages (Static Website)                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Fetch history.json                                      │
│  2. Render charts with Chart.js                             │
│  3. Display tables & KPI cards                              │
│  4. Auto-refresh every 30 seconds                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Data Structure

**`history.json`** — Complete benchmark history with all runs:

```json
{
  "runs": [
    {
      "timestamp": "2026-04-27T20:14:55Z",
      "prompt": "Write a Python function that checks if a number is prime...",
      "models": [
        {
          "model": "deepseek-ai/deepseek-v4-flash",
          "success": true,
          "responseTime": 2847,
          "tokensGenerated": 156,
          "totalTokens": 185,
          "response": "def is_prime(n):\n    if n < 2: return False\n    ...",
          "error": null
        }
      ],
      "summary": {
        "successCount": 11,
        "totalModels": 12,
        "fastestModel": "mistralai/mixtral-8x22b-instruct-v0.1",
        "fastestTime": 1234
      }
    }
  ]
}
```

**`results.json`** — Latest run results (generated for compatibility)

## Customization

### Change the Test Prompt

Edit `scripts/test-models.sh`:

```bash
PROMPT="Your custom benchmark prompt here"
```

### Add or Remove Models

Edit the `MODELS` array in `scripts/test-models.sh`:

```bash
MODELS=(
    "meta/llama-3.1-70b-instruct"
    "your/custom-model"
    # ... etc
)
```

### Change Benchmark Frequency

Edit `.github/workflows/benchmark.yml`:

```yaml
schedule:
  - cron: '0 */6 * * *'  # Every 6 hours
  # - cron: '0 0 * * *'   # Daily at midnight
  # - cron: '*/30 * * * *' # Every 30 minutes
```

### Customize Dashboard Styling

Edit the CSS in `index.html`:

```css
:root {
    --green: #76b900;        /* Primary color */
    --bg-0: #080810;         /* Background */
    --text-0: #f8fafc;       /* Text */
    /* ... more variables */
}
```

## Dashboard Sections

### 📊 Overview
- Key performance indicators
- Latest run response time comparison
- Success rate trend (last 20 runs)
- Benchmark prompt display

### ⚡ Latest Run
- Complete results table for most recent benchmark
- Sort by: response speed, token generation, model name
- Click any row to view full model response
- Real-time status indicators

### 📈 History
- Success count trend over all runs
- Sortable history table
- View all benchmarks since tracking began
- Track improvements and regressions

## Performance Notes

- **Response Times** — Measured from API request to response (includes network latency)
- **Token Generation** — Tokens generated by the model
- **Throughput** — Tokens per second (generated tokens / response time)
- **Success Rate** — Percentage of models returning valid responses

Each model is tested with:
- **Prompt**: Identical benchmark prompt (prime number function)
- **Temperature**: 0.7 (moderate randomness)
- **Top-p**: 0.9
- **Max tokens**: 500
- **Format**: OpenAI chat completions compatible

## Hosting Options

### GitHub Pages (Free & Recommended)

Already configured! Just enable it in settings.

### Netlify

```bash
git push origin main
```

Connect your repo in [Netlify](https://netlify.com) — automatic deployments!

### Vercel

```bash
git push origin main
```

Connect your repo in [Vercel](https://vercel.com) — static site hosting!

### Self-Hosted

```bash
# Copy files to your server
scp -r . your-server:/var/www/nimstats/
```

Since it's a static site, it works on any web server!

## Troubleshooting

### ❌ Benchmarks not running

**Check the logs:**
1. Go to **Actions** tab
2. Click the latest workflow run
3. Check for error messages

**Common issues:**
- `NIM_API_KEY` secret not set or incorrect
- API key expired — regenerate at [build.nvidia.com](https://build.nvidia.com)
- API quota exceeded — wait or upgrade account
- Network timeout — try manual trigger again

### ❌ Dashboard shows "Loading"

- Check browser console (F12) for errors
- Ensure `history.json` exists in the repo
- Try hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
- Check that GitHub Pages is enabled

### ❌ Some models show "No content in response"

This typically means:
- Model is temporarily unavailable on NIM API
- Model was deprecated/replaced
- API rate limits hit for that model

**Solution:** Update the models list to use current available models from [build.nvidia.com](https://build.nvidia.com/models)

## API Reference

### NVIDIA NIM API Endpoint

```
POST https://integrate.api.nvidia.com/v1/chat/completions
Authorization: Bearer YOUR_API_KEY
```

**Request Format:**
```json
{
  "model": "meta/llama-3.1-70b-instruct",
  "messages": [{"role": "user", "content": "Your prompt"}],
  "temperature": 0.7,
  "top_p": 0.9,
  "max_tokens": 500
}
```

**Response Format:**
```json
{
  "choices": [{"message": {"content": "..."}}],
  "usage": {
    "completion_tokens": 156,
    "total_tokens": 185
  }
}
```

See [NVIDIA NIM Documentation](https://docs.api.nvidia.com/nim/) for details.

## Contributing

We welcome contributions! Here are ways to help:

- 🐛 **Report bugs** — Found an issue? [Open an issue](https://github.com/MauroDruwel/NIMStats/issues)
- ✨ **Suggest features** — Ideas for improvements? [Discussions](https://github.com/MauroDruwel/NIMStats/discussions)
- 🔧 **Submit PRs** — Code improvements welcome!
- 📊 **Share results** — Show us your benchmarks and insights
- 📝 **Improve docs** — Help make documentation clearer

### Development

```bash
# Install dependencies (none required for static site!)
npm install  # optional - for linting

# Test locally
python3 -m http.server 8000
# Visit http://localhost:8000

# Make changes & commit
git add .
git commit -m "Feature: add new models"
git push origin main
```

## Project Statistics

- 📦 **Size**: ~50KB (minified, uncompressed)
- ⚡ **Performance**: Loads in <1s on typical connections
- 🔒 **Security**: No tracking, no analytics, client-side only
- 📱 **Compatibility**: Works on all modern browsers

## FAQ

**Q: Does this cost anything?**
A: No! GitHub Actions free tier allows 2,000 runs/month. Benchmarking hourly uses ~730 runs/month.

**Q: How long does each benchmark take?**
A: 2-5 minutes depending on model availability and response times.

**Q: Can I benchmark custom models?**
A: Yes! Edit the `MODELS` array in `scripts/test-models.sh`. Your models must be available on NVIDIA NIM API.

**Q: How long is data kept?**
A: We keep the last 720 runs (~30 days of hourly benchmarks). Adjust `.[0:720]` in `scripts/test-models.sh` to keep more/less history.

**Q: Can I download the data?**
A: Yes! Download `history.json` from your repo — it's plain JSON and can be imported into Excel, Python, etc.

## License

MIT License — see [LICENSE](LICENSE) for details

## Resources

- 🚀 [NVIDIA NIM Homepage](https://developer.nvidia.com/nim)
- 📚 [API Documentation](https://docs.api.nvidia.com/nim/)
- 💬 [NVIDIA Developer Forum](https://forums.developer.nvidia.com/)
- 🎯 [Model Catalog](https://build.nvidia.com/models)

## Acknowledgments

Built with ❤️ for the ML community. Special thanks to NVIDIA for the free NIM API!

---

**Made with [Chart.js](https://www.chartjs.org/) • Hosted on [GitHub Pages](https://pages.github.com/) • Powered by [NVIDIA NIM](https://developer.nvidia.com/nim)**

*Have questions or want to collaborate? Open an issue or reach out on GitHub!*
