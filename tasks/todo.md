# tasks/todo.md

## Current Status: Initial Build Complete

All three features are implemented and the app shell is in place.

---

## Completed ✅

- [x] Project setup: pubspec.yaml with all dependencies
- [x] Theme system: AppColors, AppTextStyles, AppTheme
- [x] DebugService + DebugEvent (singleton, JSON/CSV export)
- [x] Shared widgets: BlobBackground, GhostButton, AppScaffold, TimedProgressBar
- [x] App shell: main.dart, app.dart, router.dart (named routes + fade transitions)
- [x] HomeScreen: 3 feature cards, long-press → debug panel
- [x] CompletionScreen: done state, "Back to start" / "Try another"
- [x] Feature 3 – Focus Fill: liquid wave animation, duration picker, ghost controls
- [x] Feature 1 – Balancing Game: accelerometer physics, maze collision, 60s timer
- [x] Feature 2 – Thought Offloading: speech recognition, node graph, mic button animation
- [x] DebugPanel: session ID input, event log, JSON/CSV export via share sheet
- [x] iOS permissions: NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription

---

## Next Steps (Post-Testing)

### Low-priority polish
- [ ] Tweak ball physics constants (gravity scale, damping) based on physical device feel
- [ ] Add haptic feedback on ball wall collision and goal reach
- [ ] Add subtle screen shake on game goal completion
- [ ] Improve maze layout based on user testing observations

### Mid-fidelity iteration (after LoFi test)
- [ ] Refine blob animation timing and colour palette
- [ ] Add breathing rhythm sync to Focus Fill (optional, per FEATURES.md)
- [ ] Node fade-out animation on Thought Offloading exit
- [ ] Improve node text truncation for long phrases
- [ ] Add participant ID selection UX on app launch (quick-set modal)

### Research instrumentation
- [ ] Verify event schema against full FEATURES.md requirements
- [ ] Test JSON export format with research tooling
- [ ] Add rage-tap detection (5+ taps on same element within 2s)
- [ ] Add first-interaction latency tracking

---

## Known Issues / Limitations

- **Balancing Game**: Sensor not available on iOS simulator — test on physical device
- **Speech recognition**: Requires internet first-run on Android for model download
- **BlobBackground orientation lock**: Currently locks to portrait in main.dart
- **Debug panel export**: Requires Files/email/AirDrop app to actually save on device

---

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Run on connected device
flutter run -d <device-id>

# Build release IPA
flutter build ios --release
```
