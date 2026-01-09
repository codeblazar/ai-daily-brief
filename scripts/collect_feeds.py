import argparse
import datetime as dt
import email.utils
import sys
from typing import List, Dict, Any

import feedparser


FEEDS: List[Dict[str, str]] = [
    {"name": "OpenAI News", "url": "https://openai.com/news/rss.xml"},
    {"name": "Google AI Blog", "url": "https://ai.googleblog.com/feeds/posts/default"},
    {"name": "Anthropic News", "url": "https://www.anthropic.com/news/rss"},
    {"name": "Hugging Face", "url": "https://huggingface.co/blog/feed.xml"},
    {"name": "LangChain", "url": "https://blog.langchain.dev/rss/"},
    {"name": "Weights & Biases", "url": "https://wandb.ai/fully-connected/rss.xml"},
    {"name": "DeepLearning.AI (The Batch)", "url": "https://www.deeplearning.ai/the-batch/feed/"},
    {"name": "Import AI (Jack Clark)", "url": "https://jack-clark.net/feed/"},
    {"name": "fast.ai", "url": "https://www.fast.ai/index.xml"},
    {"name": "Towards Data Science", "url": "https://towardsdatascience.com/feed"},
    {"name": "TechCrunch AI", "url": "https://techcrunch.com/tag/artificial-intelligence/feed/"},
    {"name": "VentureBeat AI", "url": "https://venturebeat.com/category/ai/feed/"},
    {"name": "NVIDIA Blog", "url": "https://blogs.nvidia.com/feed/"},
    {"name": "InfoWorld AI", "url": "https://www.infoworld.com/category/machine-learning/index.rss"},
]


def parse_date(entry: Dict[str, Any]) -> dt.datetime:
    for key in ("published_parsed", "updated_parsed"):
        parsed = entry.get(key)
        if parsed:
            try:
                return dt.datetime.fromtimestamp(email.utils.mktime_tz(parsed), dt.timezone.utc)
            except Exception:
                pass
    for key in ("published", "updated"):
        text = entry.get(key)
        if text:
            try:
                return email.utils.parsedate_to_datetime(text)
            except Exception:
                pass
    return dt.datetime.now(dt.timezone.utc)


def collect(max_items: int = 15) -> List[Dict[str, str]]:
    items: List[Dict[str, str]] = []
    for feed in FEEDS:
        url = feed["url"]
        name = feed["name"]
        try:
            parsed = feedparser.parse(url)
        except Exception as exc:  # pragma: no cover - defensive
            print(f"[warn] failed to fetch {url}: {exc}", file=sys.stderr)
            continue
        if parsed.bozo:
            # Skip malformed feeds but continue overall
            print(f"[warn] feedparser bozo flag for {url}: {parsed.bozo_exception}", file=sys.stderr)
        for entry in parsed.entries[:3]:
            published = parse_date(entry)
            items.append(
                {
                    "title": entry.get("title", "Untitled").strip(),
                    "link": entry.get("link", "").strip(),
                    "source": name,
                    "published": published,
                }
            )
    items.sort(key=lambda x: x["published"], reverse=True)
    return items[:max_items]


def to_markdown(items: List[Dict[str, str]]) -> str:
    if not items:
        return "No feed items available today."
    lines = ["Recent AI headlines:"]
    for item in items:
        title = item["title"].replace("\n", " ").strip()
        link = item["link"]
        source = item["source"]
        lines.append(f"- {title} — {source} — {link}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Collect AI RSS feeds into markdown summary.")
    parser.add_argument("output", help="Path to write markdown summary")
    args = parser.parse_args()

    items = collect()
    markdown = to_markdown(items)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(markdown)


if __name__ == "__main__":
    main()
