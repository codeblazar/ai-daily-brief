#!/usr/bin/env bash
set -e

REPO_NAME="ai-daily-brief"
GITHUB_USER="$(gh api user --jq .login)"

echo "Creating MkDocs site..."
pip install --quiet mkdocs mkdocs-material

mkdocs new .

echo "Creating directory structure..."
mkdir -p docs/archive
mkdir -p .github/workflows
mkdir -p .prompts

echo "Writing mkdocs.yml..."
cat > mkdocs.yml << 'EOF'
site_name: AI Daily Brief
site_description: Practical AI briefings for instructors and practitioners

theme:
  name: material
  features:
    - navigation.sections
    - navigation.expand
    - navigation.top
    - toc.follow

plugins:
  - search
  - blog:
      blog_dir: archive
      post_date_format: yyyy-MM-dd

nav:
  - Home: index.md
  - Archive: archive/
  - About: about.md
EOF

echo "Writing homepage..."
cat > docs/index.md << 'EOF'
# AI Daily Brief

Daily, practical briefings on Artificial Intelligence.

- 5 to 10 minute reads
- Instructor and practitioner focus
- Examples over theory
EOF

echo "Writing about page..."
cat > docs/about.md << 'EOF'
# About

This site publishes short, applied AI briefings.

Each post stands alone.
EOF

echo "Writing daily prompt..."
cat > .prompts/daily-brief.txt << 'EOF'
You are generating a daily Artificial Intelligence briefing.

Audience:
- IT and AI instructors
- Practitioners

Constraints:
- 5 to 10 minute read
- Practical
- Plain English
- Markdown only

Structure:

---
title: AI Daily Brief – {{DATE}}
tags:
  - applied-ai
---

## Today in One Minute
(3 bullets)

## What Happened

## Why It Matters

## Try This Today

## Teaching Angle

## Links
EOF

echo "Writing daily generation workflow..."
cat > .github/workflows/daily-brief.yml << 'EOF'
name: Generate Daily AI Brief

on:
  schedule:
    - cron: "0 1 * * *"
  workflow_dispatch:

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set date
        run: echo "DATE=$(date +'%Y-%m-%d')" >> $GITHUB_ENV

      - name: Generate brief
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          mkdir -p docs/archive
          PROMPT=$(sed "s/{{DATE}}/${DATE}/g" .prompts/daily-brief.txt)

          curl https://api.openai.com/v1/chat/completions \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
              \"model\": \"gpt-4.1-mini\",
              \"messages\": [
                {\"role\": \"user\", \"content\": \"$PROMPT\"}
              ]
            }" | jq -r '.choices[0].message.content' \
            > docs/archive/${DATE}.md

      - name: Commit and push
        run: |
          git config user.name "ai-brief-bot"
          git config user.email "bot@users.noreply.github.com"
          git add docs/archive/${DATE}.md
          git commit -m "Add AI Daily Brief for ${DATE}" || exit 0
          git push
EOF

echo "Writing deploy workflow..."
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy MkDocs

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: 3.x
      - run: pip install mkdocs-material
      - run: mkdocs gh-deploy --force
EOF

echo "Initialising git..."
git init
git add .
git commit -m "Initial AI Daily Brief setup"

echo "Creating GitHub repo..."
gh repo create "$REPO_NAME" --public --source=. --push

echo "Bootstrap complete."