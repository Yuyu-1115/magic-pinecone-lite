# Magic Pinecone Lite App

Flutter web app for the course selection slice of Magic Pinecone Lite.

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
