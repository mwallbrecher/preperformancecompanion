# tasks/lessons.md

Lessons learned during development. Updated after corrections or non-obvious choices.

---

## Sensor Handling (Balancing Game)

**Rule:** Use a low-pass filter before applying accelerometer data to physics.
**Why:** Raw `AccelerometerEvent` data is very noisy, especially on older devices. Without filtering, the ball jitters constantly even when the phone is still.
**How to apply:** `smoothed = alpha * raw + (1 - alpha) * previous` with alpha ~0.2–0.3. Lower alpha = smoother but more lag.

---

## Physics Coordinate Mapping

**Rule:** On portrait iOS, `event.x` is lateral tilt (positive = tilt right), `event.y` is forward/back tilt (positive = tilt back = move up the screen). Negate x and use y directly for intuitive feel.
**Why:** The accelerometer measures gravity vector, so tilting right gives a positive x reading. Negating maps it to screen physics naturally.
**How to apply:** `gravityX = -event.x`, `gravityY = event.y`.

---

## RepaintBoundary for Performance

**Rule:** Always wrap heavy CustomPaint widgets (FillPainter, GamePainter, NodePainter) in RepaintBoundary.
**Why:** Without it, blob background animations or other parent rebuilds trigger unnecessary repaints of the fill/game canvas.
**How to apply:** `RepaintBoundary(child: CustomPaint(...))` at the compositing boundary.

---

## Speech Recognition Lifecycle

**Rule:** Call `SpeechToText.initialize()` once, then `listen()` / `stop()` per session. Don't re-initialize on each tap.
**Why:** Initialisation is expensive (~500ms). Re-initialising causes noticeable delay and sometimes fails silently on iOS.
**How to apply:** Initialise in `ThoughtOffloadingNotifier.initialize()` called once in `initState`.

---

## FocusFillNotifier Ticker

**Rule:** Pass the `TickerProvider` (the screen's State mixin) into the notifier's `start()` method rather than storing it.
**Why:** The notifier outlives individual build calls but the vsync comes from the widget's State. Storing a stale vsync causes assertions in debug mode.
**How to apply:** `notifier.start(this)` where `this` is the State with `TickerProviderStateMixin`.

---

## Navigator After Async Gaps

**Rule:** Always check `if (!mounted) return;` before calling `Navigator` methods after any async gap (Future, await, addPostFrameCallback).
**Why:** The widget tree may have been disposed (e.g. user pressed back) while an async op was in flight. Calling Navigator on a disposed context throws.
**How to apply:** Guard every post-async navigation call.

---

## Debug Panel Touch Isolation

**Rule:** Wrap the debug panel background dismiss area with `HitTestBehavior.opaque` and the inner container with a no-op `GestureDetector`.
**Why:** Without this, taps on the panel pass through to the HomeScreen behind it, accidentally triggering feature card navigation.
**How to apply:** See `DebugPanel` implementation — outer `GestureDetector(onTap: onClose, behavior: HitTestBehavior.opaque)` with inner `GestureDetector(onTap: () {})`.
