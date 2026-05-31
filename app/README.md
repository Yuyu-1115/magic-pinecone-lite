# Magic Pinecone Lite App

Magic Pinecone（神奇松果）is a campus service project developed by Google
Developers on Campus NCU. The project aims to bring scattered campus
information and fragmented university system features into one convenient
service for NCU students.

This Flutter web app is the Lite trial version focused on course selection. It
regularly syncs course information, lets students save selected courses locally,
supports sharing selected courses with others, and provides a responsive layout
for both phone and desktop use.

The app consumes static course JSON from the `magic-pinecone-lite` data branches:

- `courses.json` from the active semester branch
- `detail/<serial_no>.json` for course detail panes

## Local Development

```bash
flutter pub get
flutter run -d chrome
```

## GitHub Pages Build

Use a base href that matches the repository path:

```bash
flutter build web --release --base-href /magic-pinecone-lite/
```
