# Graft Zähler (Graftcount)

A Flutter app for **manually counting and tracking hair-transplant grafts** across a working session and exporting the results as CSV or PDF. Built as a focused, single-purpose tool with offline-first local storage.

> **Status:** Working prototype. Core counting, persistence, and export/print features are implemented. This is a **manual** counting tool — it does **not** use machine learning or image detection.

## Features

- Enter and count grafts organized by day and by petri dish
- Automatic local persistence — data is restored on the next launch (via `shared_preferences`)
- Data is saved as you type and when the app goes to the background
- **CSV export** of the recorded counts
- **PDF export** with a landscape, print-friendly report layout and Unicode font support
- Direct **print / print-preview** via the system print dialog
- Custom-drawn app logo and icon

## Tech stack

- **Flutter / Dart** (`sdk: ^3.10.4`)
- `shared_preferences` — local key/value persistence
- `pdf` + `printing` — PDF generation and printing
- `path_provider` — file access for exports
- `flutter_lints` for static analysis, `flutter_launcher_icons` for app icons

## Screenshots

_Screenshots are not included yet._

<!-- TODO: add screenshots to docs/ or assets/ and embed them here, e.g.:
![Counting screen](docs/screenshot-counting.png)
![PDF report](docs/screenshot-report.png)
-->

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.10+).

```bash
git clone https://github.com/BotondCsereklye/Graftcount.git
cd Graftcount
flutter pub get
flutter run
```

## Tests

A widget smoke test verifies that the main screen and the export/print controls render:

```bash
flutter test
```

## Project structure

```text
.
├── lib/
│   └── main.dart            # App entry point, counting UI, persistence, CSV/PDF export, printing
├── test/
│   └── widget_test.dart     # Widget smoke test for the main screen
├── assets/
│   └── logo.jpeg            # App icon source
├── web/                     # Flutter web bootstrap
├── analysis_options.yaml    # Lint configuration
└── pubspec.yaml
```

## Known limitations

- Data entry and counting are **fully manual** — there is no automatic graft detection.
- Persistence uses local device storage only; there is no backend, sync, or multi-device support.
- Test coverage is currently a single widget smoke test.
- Most of the app logic lives in one `main.dart` file and would benefit from being split into smaller widgets/services.

## Next steps

- Split `main.dart` into separate widget and service files
- Add screenshots and a short usage guide
- Expand tests around the counting and export logic
- Consider a cleaner data model for days / petri dishes / grafts
