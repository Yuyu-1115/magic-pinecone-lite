# Magic Pinecone Lite

> [English](../README.md) | 正體中文

神奇松果是由學生社群 Google Developers on Campus NCU 正在開發中的軟體。期望能夠將零碎的校務資訊、分散的系統功能整合起來，為中大學生提供一個一站式的服務。

Magic Pinecone Lite（神奇松果 Lite）是目前的試行版本，聚焦於選課體驗與靜態資料同步。支援定期同步最新課程資訊、本機儲存選課資訊與分享給他人，並提供手機與電腦皆適用的基本 RWD 介面。

專案目前主要可以分為兩個部分：

- `app/`：Flutter Web 應用程式，用於查詢課程、建立課表，以及分享已選課程。
- `scripts/`：Python 資料同步流程，用於產生課程與獎助學金相關的靜態 JSON。

## 功能

- **課程查詢**：從靜態 JSON 分支瀏覽中央大學課程資料。
- **課表預覽**：加入或移除課程，並在本機預覽課表結果。
- **分享連結**：將已選課程編碼為精簡的分享碼，讓其他使用者可以開啟。
- **靜態資料同步**：擷取課程、課程詳細資訊、獎助學金與工讀資訊，並輸出為 JSON 檔案。
- **GitHub Pages 部署**：從 release tag 建置並部署 Flutter Web 應用程式。

## 資料分支

產生後的資料會發布到專用分支，前端可直接經由 GitHub raw URL 讀取。

- 課程列表：
  ```text
  https://raw.githubusercontent.com/magic-pinecone/magic-pinecone-lite/<semester>/courses.json
  ```

- 課程詳細資訊：
  ```text
  https://raw.githubusercontent.com/magic-pinecone/magic-pinecone-lite/<semester>/detail/<serial_no>.json
  ```

- 獎助學金與工讀資訊：
  ```text
  https://raw.githubusercontent.com/magic-pinecone/magic-pinecone-lite/data-scholarship/scholarships.json
  ```

## 開始使用

### 前置需求

- Flutter SDK，建議使用最新 stable 版本
- Dart SDK
- Python 3.13+
- [uv](https://github.com/astral-sh/uv)

### Flutter App

```bash
cd app
flutter pub get
flutter run -d chrome
```

### 資料同步

```bash
uv sync
uv run python scripts/fetch_data.py
```

爬蟲會將產生的檔案寫入 `dist/`：

- `dist/semester.txt`
- `dist/courses.json`
- `dist/detail/<serial_no>.json`
- `dist/scholarships.json`

## 部署

Flutter Web 應用程式會經由 `.github/workflows/pages.yml` 部署到 GitHub Pages。

符合 `v*.*.*` 的 release tag 會觸發：

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /magic-pinecone-lite/
```

資料同步 workflow 會定期執行，也可以從 GitHub Actions 手動觸發。

## 致謝

**OpenTPI（昕力資訊）**：與昕力資訊 OpenTPI 開放原始碼專案計畫於 2025-2026 年度的合作，是促成神奇松果的起點。

**Course Finder Fetcher**：[NCU-Course-Finder-DataFetcher-v2](https://github.com/zetaraku/NCU-Course-Finder-DataFetcher-v2)

## 生成式 AI 使用說明

本專案部分程式碼、審閱與文件撰寫曾使用生成式 AI 工具協助；最終程式碼與專案決策仍由維護者負責。

## 授權

本專案採用 MIT License，詳情請參考 [LICENSE](../LICENSE)。
