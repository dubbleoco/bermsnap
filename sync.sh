#!/bin/bash
# sync.sh — Pull live Berm data and push to GitHub Pages
set -e

BERM_WS="/Users/dubbleo/.openclaw/workspace-berm"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 Syncing Berm data..."

# Copy source files
cp "$BERM_WS/EVENT_PIPELINE.json" "$REPO_DIR/EVENT_PIPELINE.json"
cp "$BERM_WS/KPI_SNAPSHOT.json"   "$REPO_DIR/KPI_SNAPSHOT.json"
cp "$BERM_WS/TASK_QUEUE.json"     "$REPO_DIR/TASK_QUEUE.json"
cp "$BERM_WS/REVENUE_LOG.csv"     "$REPO_DIR/REVENUE_LOG.csv"

# Regenerate data.json
python3 - <<'PYEOF'
import json, csv, datetime, os

repo = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(repo, 'KPI_SNAPSHOT.json')) as f:
    kpi = json.load(f)
with open(os.path.join(repo, 'EVENT_PIPELINE.json')) as f:
    events = json.load(f)
with open(os.path.join(repo, 'TASK_QUEUE.json')) as f:
    tasks = json.load(f)

revenue_history = []
with open(os.path.join(repo, 'REVENUE_LOG.csv')) as f:
    reader = csv.DictReader(f)
    for row in reader:
        revenue_history.append(row)

data = {
    'generated': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'kpi': kpi,
    'events': events,
    'tasks': tasks,
    'revenue_history': revenue_history
}

with open(os.path.join(repo, 'data.json'), 'w') as f:
    json.dump(data, f, indent=2)

print(f"✅ data.json written — {len(events)} events, {len(tasks)} tasks, {len(revenue_history)} revenue rows")
PYEOF

# Commit and push
cd "$REPO_DIR"
git add data.json EVENT_PIPELINE.json KPI_SNAPSHOT.json TASK_QUEUE.json REVENUE_LOG.csv
git commit -m "data: sync $(date '+%Y-%m-%d %H:%M')" || echo "Nothing new to commit"
git push origin main

echo "✅ Dashboard synced → https://dubbleoco.github.io/bermsnap/"
