# Magic Pinecone Lite

> English | [正體中文](docs/README.zh-TW.md)

Magic Pinecone（神奇松果）is a campus service project developed by Google
Developers on Campus NCU. The project aims to bring scattered campus
information and fragmented university system features into one convenient
service for NCU students.

Magic Pinecone Lite is the current trial version. It focuses on course
selection while keeping the static data pipeline that powers the app: course
search, timetable preview, course sharing, and generated course/scholarship
data.

This repository contains two parts:

- `app/`: Flutter web app for searching courses, building a timetable, and sharing selected courses.
- `scripts/`: Python data synchronization pipeline for generating static course and scholarship JSON.

## Features

- **Course Search**: Browse NCU course data from static JSON branches.
- **Timetable Preview**: Add or remove courses and preview the resulting timetable locally.
- **Share Links**: Encode selected courses into a compact share code that can be opened by another user.
- **Static Data Pipeline**: Scrape course, course detail, scholarship, and part-time job data into JSON files.
- **GitHub Pages Deployment**: Build and deploy the Flutter web app from release tags.

## Data Branches

Generated data is published to dedicated branches and consumed directly through GitHub raw URLs.

- Course list:
  ```text
  https://raw.githubusercontent.com/magic-pinecone/magic-pinecone-lite/<semester>/courses.json
  ```

- Course detail:
  ```text
  https://raw.githubusercontent.com/magic-pinecone/magic-pinecone-lite/<semester>/detail/<serial_no>.json
  ```

- Scholarship and part-time job data:
  ```text
  https://raw.githubusercontent.com/magic-pinecone/magic-pinecone-lite/data-scholarship/scholarships.json
  ```

## Getting Started

### Prerequisites

- Flutter SDK, latest stable version recommended
- Dart SDK
- Python 3.13+
- [uv](https://github.com/astral-sh/uv)

### Flutter App

```bash
cd app
flutter pub get
flutter run -d chrome
```

### Data Synchronization

```bash
uv sync
uv run python scripts/fetch_data.py
```

The scraper writes generated files to `dist/`:

- `dist/semester.txt`
- `dist/courses.json`
- `dist/detail/<serial_no>.json`
- `dist/scholarships.json`

## Deployment

The Flutter web app is deployed to GitHub Pages by `.github/workflows/pages.yml`.

Release tags matching `v*.*.*` trigger:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /magic-pinecone-lite/
```

The data synchronization workflow runs on schedule and can also be triggered manually from GitHub Actions.

## Acknowledgement

**OpenTPI（昕力資訊）**: The 2025-2026 OpenTPI open source program helped initiate Magic Pinecone.

**Course Finder Fetcher**: [NCU-Course-Finder-DataFetcher-v2](https://github.com/zetaraku/NCU-Course-Finder-DataFetcher-v2)

## Generative AI Usage

Parts of this project were implemented, reviewed, or documented with assistance from generative AI tools. Human maintainers remain responsible for the final code and project decisions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
