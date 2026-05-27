# heaLife — Health Research Prototype

A cross-platform mobile app for daily health data collection in research studies. Built with Flutter, runs on both iOS and Android.

---

## Design Choices

**Framework — Flutter.** One codebase for both platforms. On iOS it reads from Apple HealthKit, on Android from Health Connect, using the `health` package as a bridge.

**Backend — Supabase.** A hosted Postgres database handles authentication and stores every submission. Participants sign up with a participant ID and password — no real email address needed. Consent is recorded in the profile and the survey is locked until it is given.

**Screen flow:**
```
Login / Register  →  Consent  →  Daily Survey  →  Review  →  Result
```
After submission there is a History screen with weekly trend charts so participants can see their own data over time. The app also supports 11 languages and light / dark themes.

**What the survey collects:**
- Wellbeing (1–5) and sleep quality (1–5)
- Neuropathic pain (0–10) and musculoskeletal pain (0–10)
- Optional: weight, blood glucose, menstrual status (for female participants)
- Free-text comment

**Health metrics read automatically from the phone:**
steps, heart rate, resting heart rate, sleep duration, active energy, walking speed, step length, gait asymmetry, double support time, floors climbed, distance walked, headphone audio exposure.

All of this is combined into one JSON payload and sent to the server on submit.

---

## Data Schema

```json
{
  "schema_version": "1.0",
  "submission": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp_utc": "2026-05-27T09:15:00.000Z",
    "app_version": "0.1.0"
  },
  "participant": {
    "id": "P-001",
    "age_range": "25–34",
    "gender": "female"
  },
  "self_report": {
    "wellbeing_rating":  { "value": 4, "scale_min": 1, "scale_max": 5, "scale_description": "1=very poor, 5=excellent" },
    "sleep_quality":     { "value": 3, "scale_min": 1, "scale_max": 5, "scale_description": "1=very poor, 5=excellent" },
    "pain": {
      "neuropathic":     { "value": 2, "descriptor": "burning/tingling/electric", "scale_min": 0, "scale_max": 10 },
      "musculoskeletal": { "value": 1, "descriptor": "aching/stiffness/pressure", "scale_min": 0, "scale_max": 10 }
    },
    "weight_kg": 65.0,
    "blood_glucose_mgdl": 98.0,
    "menstrual_status": { "on_period": false, "cycle_day": 12, "cycle_phase": "follicular" },
    "comment": "Felt a bit tired in the afternoon."
  },
  "health_metrics": [
    { "type": "step_count",      "value": 8432, "unit": "count", "aggregation": "sum",     "period_start_utc": "2026-05-27T00:00:00Z", "period_end_utc": "2026-05-27T09:15:00Z", "source": "HealthKit" },
    { "type": "heart_rate",      "value": 72,   "unit": "bpm",   "aggregation": "latest",  "period_start_utc": "2026-05-26T09:15:00Z", "period_end_utc": "2026-05-27T09:15:00Z", "source": "HealthKit" },
    { "type": "sleep_duration",  "value": 7.2,  "unit": "hours", "aggregation": "sum",     "period_start_utc": "2026-05-26T18:00:00Z", "period_end_utc": "2026-05-27T09:15:00Z", "source": "HealthKit" },
    { "type": "walking_speed",   "value": 4.8,  "unit": "km/h",  "aggregation": "average", "period_start_utc": "2026-05-27T00:00:00Z", "period_end_utc": "2026-05-27T09:15:00Z", "source": "HealthKit" }
  ],
  "device": { "platform": "iOS" }
}
```

Every metric has `period_start_utc` and `period_end_utc` so the time window is always clear. If a metric is not available or the permission is denied, it is left out of the array — the rest of the payload stays valid.

---

## How can you Build and Run

### What You Need

- Flutter 3.44 or newer (`flutter --version` to check)
- iOS: a Mac with Xcode 15 or newer
- Android: Android Studio with SDK 34 or newer

### Run on iOS — Simulator

1. Open the **Simulator** app on your Mac (search it in Spotlight or find it in Xcode → **Open Developer Tool → Simulator**).
2. It starts with a default iPhone. If you want a different model, go to **File → Open Simulator → iOS** and pick one.
3. Run:

```bash
flutter devices
# look for a line that says "(simulator)" and copy the name

flutter run -d "iPhone 16 (18.4)"    # use the name you copied
```


### Run on iOS — Physical iPhone

1. Connect your iPhone to the Mac with a **USB cable**.
2. On the iPhone, tap **Trust** when it asks if you trust this computer.
3. Open **Xcode** once — go to **Xcode → Settings → Accounts** and add your Apple ID. This signs the app so it can run on your phone.
4. On iPhone: **Settings → Privacy & Security → Developer Mode → turn on** (iOS 16 and above only).
5. Run:

```bash
flutter devices
# look for a line that says "(mobile)" and copy the name

flutter run -d "iPhone 16 Pro"       # use the name you copied
```

When the app starts, accept the HealthKit permission dialog.


### Run on Android — Physical Device

1. Connect your Android phone to the computer with a **USB cable**.
2. On the phone, go to **Settings → About Phone** and tap **Build Number 7 times**. This unlocks Developer Options.
3. Go back to **Settings → Developer Options** and turn on **USB Debugging**.
4. A dialog appears on the phone asking to allow USB debugging from this computer — tap **Allow**.
5. Run:

```bash
flutter devices
# look for a line that says "(mobile)" and copy the name

flutter run -d "Pixel 8 Pro"      # use the name you copied
```

When the app starts, accept the Health Connect permission dialog.

> **Health Connect note:** It comes pre-installed on Android 14 and above. On older devices, install it from the Play Store first.

---

### Run on Android — Emulator (first time only)

1. Open Android Studio.
2. Click **More Actions → Virtual Device Manager** (or go to **Tools → Device Manager**).
3. Click **Create Device**.
4. Pick a phone — for example **Pixel 8** — and click Next.
5. Download a system image. Choose one with **API 34 or higher** (Android 14+). Click the download arrow next to it, wait, then click Next.
6. Click **Finish**. The emulator appears in the list.
7. Press the **Play** button (▶) to start it.

Then come back to the terminal and check what Flutter can see:

```bash
flutter devices
```

Example output:

```
sdk gphone64 (emulator)  • emulator-5554 • android
Pixel 8 Pro (mobile)     • R3CN...       • android
```

Then use the name or ID:

```bash
flutter run -d "Pixel 8 Pro"      # physical Android phone
flutter run -d "emulator-5554"    # Android emulator
```

When the app starts, accept the Health Connect permission dialog.


### All Platforms

```bash
flutter pub get        # install dependencies
flutter run            # pick a device from the list
```
