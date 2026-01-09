# AI Daily Brief

Material for MkDocs site that publishes short, practical AI briefings.

## Prerequisites
- Python 3.10+ with `pip`
- GitHub CLI (`gh`) authenticated to your account

## Setup
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Local development
```bash
mkdocs serve
```
Visit the preview at http://127.0.0.1:8000.

## Content sources
Daily briefs pull from curated RSS feeds (examples): OpenAI News, Google AI Blog, Anthropic News, Hugging Face, LangChain, W&B Fully Connected, DeepLearning.AI (The Batch), Import AI, fast.ai, Towards Data Science, TechCrunch AI, VentureBeat AI, NVIDIA Blog, InfoWorld AI. You can edit the list in `scripts/collect_feeds.py`.

## Deploying locally
```bash
mkdocs gh-deploy --force
```
This builds and pushes the site to the `gh-pages` branch.

## Automation
- **Daily brief generator:** `.github/workflows/daily-brief.yml`
  - Requires repo secret `OPENAI_API_KEY`
  - Manually run via Actions tab (“Generate Daily AI Brief”) or wait for the daily schedule
- **Deploy on push:** `.github/workflows/deploy.yml` pushes to `gh-pages` on `main` updates.

## Content
- Main pages: `docs/index.md`, `docs/about.md`
- Generated posts: `docs/archive/`
