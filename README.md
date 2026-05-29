# Magic Pinecone Backend Light 🌲

Welcome to the **Magic Pinecone Backend Light** repository! 

This repository is built as a **serverless static data pipeline**. It runs automatically using GitHub Actions to scrape and format campus data from National Central University (NCU), publishing the resulting clean JSON payloads directly to an orphan branch named `data`.

## 🚀 How it Works

1. **Automatic Scraping**: GitHub Actions automatically triggers the scraper script (`scripts/fetch_data.py`) **every 10 minutes** (optimized for capturing rapid changes during the peak course selection periods).
2. **Robust Exception Handling**: The scraper is configured to propagate errors. If a core category fetch (scholarship or course list) fails, the execution terminates with a non-zero exit status code, causing the GitHub Action to fail and preventing the publishing of incomplete data. Minor errors (such as individual course detail fetch failures) are gracefully tolerated.
3. **Orphan Branch Hosting**: The Action packages the output files into `dist/` and force-pushes them to a dedicated orphan branch named `data`.
4. **Static CDN Access**: The resulting JSON files are hosted directly and completely for free via GitHub's CDN.

---

## 📦 Consuming the Data

Frontend clients can consume the raw JSON data directly using the following URL structure (replace `<owner>` and `<repo>` with your GitHub organization/user and repository name):

* **Course List**:
  `https://raw.githubusercontent.com/<owner>/<repo>/data/courses.json`
  *Contains the main list of NCU courses, including metadata, teacher, times, selection limits, and enrollment counts.*

* **Individual Course Detail**:
  `https://raw.githubusercontent.com/<owner>/<repo>/data/detail/<serial_no>.json`
  *Contains granular details for a specific course (e.g. objectives, content, books, teaching methods, and grading policy), keyed by its 5-digit serial number.*

* **Scholarship & Part-time Job Data**:
  `https://raw.githubusercontent.com/<owner>/<repo>/data/scholarships.json`
  *Contains parsed NCU scholarship and part-time job announcements, including download links and content summaries.*

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
   - `dist/courses.json` (Includes all courses with basic info)
   - `dist/detail/<serial_no>.json` (Granular details for each course; empty detail pages are automatically filtered out to save storage space)
   - `dist/scholarships.json` (Parsed scholarship and part-time job announcements)

---

## 🎖️ Credits

This backend logic was built, reviewed, and refined with the help of AI coding assistants:
- **GitHub Copilot** (for identifying the critical exception handling and data branch overwrite vulnerability during code review).
- **Antigravity (by Google DeepMind)** (for implementing the bug fixes, optimizing scheduling, and updating the repository configuration).
