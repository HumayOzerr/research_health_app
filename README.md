# Health Research Study — Mobile Prototype

A minimal cross-platform mobile prototype for collecting participant wellbeing data and native health metrics, built with Flutter.

---

## Design Choices

**Framework:** Flutter was chosen for its single codebase that targets both iOS (HealthKit) and Android (Health Connect) through the [`health`](https://pub.dev/packages/health) package, reducing duplication while maintaining native API access.

**Screen flow:** Four screens form a linear, one-way flow — Welcome → Form → Review → Result — so participants always know where they are and can review everything before submitting.

**Health metric:** Step count for today (midnight to now) was selected as the primary metric because it is the most reliably available data type on both HealthKit and Health Connect, and requires only a single read permission.

**Mock endpoint:** Submissions are POST-ed to `https://httpbin.org/post`, which echoes the full JSON payload back. No backend setup is required to verify the transmission.

**State management:** Plain `StatefulWidget` / `setState` — no external state library. The task scope does not warrant additional complexity.

---

## Data Schema

```json
{
  "schema_version": "1.0",
  "submission": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp_utc": "2026-05-20T14:30:00.000Z",
    "app_version": "0.1.0"
  },
  "participant": {
    "id": "P-001",
    "age_range": "25–34"
  },
  "self_report": {
    "wellbeing_rating": {
      "value": 4,
      "scale_min": 1,
      "scale_max": 5,
      "scale_description": "1=very poor, 5=excellent"
    },
    "comment": "Felt energetic in the morning."
  },
  "health_metrics": [
    {
      "type": "step_count",
      "value": 8432,
      "unit": "count",
      "aggregation": "sum",
      "period_start_utc": "2026-05-20T00:00:00.000Z",
      "period_end_utc": "2026-05-20T14:30:00.000Z",
      "source": "HealthKit"
    }
  ],
  "device": {
    "platform": "iOS"
  }
}
```

Key design decisions in the schema:
- `schema_version` allows the server to handle payload evolution without breaking existing parsers.
- `period_start_utc` / `period_end_utc` make the step-count window explicit — raw counts without a time window are not meaningful in research contexts.
- `source` distinguishes HealthKit (iOS) from Health Connect (Android) for provenance tracking.
- If health permission is denied or no data is available, `health_metrics` is an empty array rather than null, keeping the schema consistent.

---

## How to Build & Run

### Prerequisites

- Flutter 3.44+ (`flutter --version`)
- Xcode 15+ with iOS 14+ simulator (for iOS)
- Android Studio with Android SDK 34+ (for Android)

### iOS Simulator

```bash
# Open simulator first
open -a Simulator

# Run
cd research_health_app
flutter run -d "iPhone 17"
```

> **Note on HealthKit in Simulator:** The iOS Simulator supports HealthKit but step data must be added manually via the Health app. On a physical iPhone, real accumulated data is used automatically.

### Physical iPhone

1. Connect iPhone via USB cable.
2. On iPhone: **Settings → Privacy & Security → Developer Mode → On** (iOS 16+).
3. On Mac, trust the device when prompted in Xcode.
4. Run:
   ```bash
   flutter run -d <device-name>
   ```
5. Accept the HealthKit permission dialog when it appears.

### Android Emulator / Device

```bash
flutter run -d <android-device>
```

Health Connect must be installed on the device (pre-installed on Android 14+). The app will request `READ_STEPS` permission via the Health Connect permission dialog.

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Material 3 theme setup
├── theme/app_theme.dart       # Colour palette and widget defaults
├── models/submission.dart     # Data model + toJson() serialisation
├── services/
│   ├── health_service.dart    # HealthKit / Health Connect wrapper
│   └── api_service.dart       # HTTP POST to mock endpoint
└── screens/
    ├── welcome_screen.dart    # Intro + permission request
    ├── form_screen.dart       # Participant form (ID, age, rating, comment)
    ├── review_screen.dart     # Review form + health data before submit
    └── result_screen.dart     # Success / failure + raw JSON display
```
