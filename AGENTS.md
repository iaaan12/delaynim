# AGENTS.md

## What this is
Static dashboard that benchmarks ~20 NVIDIA NIM models via GitHub Actions. Pure Python stdlib + vanilla HTML/JS. No package manager, no build step, no tests, no linter.

## Data flow
```
GitHub Actions (workflow_dispatch)
  -> scripts/test_models.py     (calls NVIDIA NIM API per model)
  -> scripts/results.json       (temp artifact, gitignored)
  -> scripts/merge_results.py   (combines group1 + group2)
  -> history.db                 (SQLite, committed to repo)
  -> index.html                 (loads via sql.js WASM, fully client-side)
```

## Commands

### Serve dashboard locally
```bash
python3 -m http.server 8000
# Open http://localhost:8000
```
Must be HTTP — `file://` won't work (sql.js needs `fetch('history.db')`).

### Run benchmarks locally
```bash
export NIM_API_KEY=your_key_here   # required
python3 scripts/test_models.py
```
Env vars:
- `NIM_API_KEY` (required) — from build.nvidia.com
- `MODEL_GROUP` — `group1` | `group2` | `all` (default `all`; CI uses `group1`/`group2` for parallelism)
- `API_BASE` — default `https://integrate.api.nvidia.com/v1`
- `REQUEST_TIMEOUT_SECONDS` — default `300`

### One-time migration (history.json -> history.db)
```bash
python3 scripts/migrate_to_sqlite.py
```
Only needed when upgrading from the legacy JSON format. Removes defunct models listed in `REMOVED_MODELS`.

## Architecture notes

- **No tests, no linter, no formatter, no type checker.** CI only runs the benchmark workflow.
- **No `requirements.txt` / `pyproject.toml`.** Scripts use stdlib only.
- **No build step.** `index.html` ships as-is. External deps via CDN: Chart.js, sql.js.
- **Schema** lives in `scripts/db_utils.py` (`init_schema`). Two tables: `runs` and `model_results`. `MAX_RUNS = 720` — older runs are pruned automatically on insert.
- **Dashboard** is a single `index.html` (1547 lines). Tabs: `overview`, `leaderboard`, `explorer`, `timeline`, `compare`.

## Common edits

| Change | File |
|---|---|
| Add/remove benchmarked models | `ALL_MODELS` in `scripts/test_models.py` |
| Change benchmark prompt | `PROMPT` in `scripts/test_models.py` |
| Change schedule | `.github/workflows/benchmark.yml` (add `schedule:` block — currently only `workflow_dispatch`) |
| Change dashboard copy/colors | `index.html` (CSS vars in `:root`, content in body) |
| Defunct model cleanup | `REMOVED_MODELS` in `scripts/migrate_to_sqlite.py` |

## CI quirks

- Workflow: `.github/workflows/benchmark.yml`
- 3 jobs: `test_group1`, `test_group2` (parallel), `merge_and_update` (depends on both)
- Each group writes `scripts/results.json`, uploaded as artifact
- Merge job downloads artifacts, renames to `results-group1.json` / `results-group2.json`, runs `merge_results.py`, commits `history.db`
- README claims "every hour" but the workflow currently has **no `schedule:` block** — only `workflow_dispatch`. Add one if hourly cron is wanted.
- Required secret: `NIM_API_KEY`

## Gitignored
- `history.json` (legacy)
- `scripts/results*.json` (temp artifacts)
- `.env`, Python caches, Node files (forward-compat)
