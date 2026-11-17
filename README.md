# Osnap

Flutter app that scans receipts and tracks item prices.

- Take a photo of a receipt (or pick one from the gallery). The text is read on the device, offline.
- Each item gets a quantity, total price and per-piece price (`total / qty`).
- Optional title and note per receipt. The history list shows the title, or the date when there is none.
- Optional markup in pesos per piece, e.g. ₱10 + ₱4 = ₱14. An item bought before keeps its last markup.
- The same item on a later receipt is compared with the earlier one (▲ up, ▼ down, or no change), with a price chart per item.
- Backup and restore (.zip), CSV export, dark mode.
- Optional "Fix with AI" for messy receipts.

## Run

```sh
flutter pub get
dart run build_runner build   # only after changing lib/data/database.dart
flutter run
```

## iOS setup (one time)

The text recognition plugin needs two things on iOS:

1. Linker flags `-ObjC -all_load`. Already set in `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`.
2. The ML Kit model bundle. Download `LatinOCRResources.bundle` from the
   [google-mlkit-swiftpm 9.0.3 release](https://github.com/d-date/google-mlkit-swiftpm/releases/tag/9.0.3)
   and add it to the `Runner` target in Xcode under **Build Phases > Copy Bundle Resources**.
   Without it, scanning on iOS returns no text.

Android needs no extra setup.

## AI clean-up (optional)

Settings > AI clean-up. The app talks to any OpenAI-compatible `/chat/completions` service:

| Service | Service URL | Key | Model example |
|---|---|---|---|
| GitHub Models (default) | `https://models.github.ai/inference` | GitHub token with the `models: read` permission | `openai/gpt-4.1-mini` |
| Ollama on your computer | `http://<computer-ip>:11434/v1` | leave empty | `llama3.2-vision` |
| LM Studio | `http://<computer-ip>:1234/v1` | leave empty | the loaded model's name |

Turn off "Send the photo too" for models that cannot read images; only the scanned text is sent then.

## Code layout

```
lib/
  core/         formatting helpers, shared widgets
  data/         drift database (receipts, products, line items), providers
  services/     OCR, receipt parser, AI client, product matching, backup
  features/
    scan/       camera/gallery flow and the review screen
    history/    receipt list and receipt detail
    products/   price list and per-item price history
    settings/
test/           receipt parser tests
```

Money is stored as integer centavos. Photos are kept in the app's `receipts/` folder; the database stores the file name.
