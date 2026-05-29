# Magic Pinecone Data 🌲

Welcome to the **Magic Pinecone Data** repository! 

This repository has been reconstructed into a purely **serverless static data pipeline**. It runs daily using GitHub Actions to scrape and format campus data from National Central University (NCU) and publishes the results in JSON format on an orphan branch named `data`.

## 🚀 How it Works

1. **Daily Automatic Scrapes**: GitHub Actions automatically triggers the scraper script (`scripts/fetch_data.py`) **every day at 04:00 AM Taiwan Time (UTC 20:00)**.
2. **Orphan Branch Hosting**: The Action packages the output files into `dist/` and force-pushes them to a dedicated orphan branch named `data`.
3. **Free Static Hosting / CDN**: The resulting JSON files are hosted directly and completely for free via GitHub's CDN.

---

## 📦 Consuming the Data

Frontend clients can consume the raw JSON data directly from the following URLs. Replace `<owner>` and `<repo>` with your GitHub organization/user and repository name:

* **Course Data**:
  `https://raw.githubusercontent.com/<owner>/<repo>/data/courses.json`
* **Scholarship & Part-time Job Data**:
  `https://raw.githubusercontent.com/<owner>/<repo>/data/scholarships.json`

---

## 🛠️ Local Development & Scraping

If you want to run the scraper manually in your local environment:

### Prerequisites
- Install [uv](https://github.com/astral-sh/uv) (this project requires Python 3.13+)

### Quick Start
1. **Sync Dependencies**:
   ```bash
   uv sync
   ```

2. **Run Scraper**:
   ```bash
   uv run python scripts/fetch_data.py
   ```

3. **Check Outputs**:
   After execution, check the generated files under the `dist/` directory:
   - `dist/courses.json` (Includes all courses with a direct `detail_url` link pointing to the official NCU Course System detail page)
   - `dist/scholarships.json` (Includes parsed scholarship and part-time job announcements)
