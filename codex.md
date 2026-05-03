# CODEX.md

## Workflow Orchestration

### 1. PLan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity
### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution
### 3. Self-Improvement Loop
- After ANY correction from the user: update tasks/lessons. md" with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project
### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check Logs, demonstrate correctness
### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause
and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it
### 6. Autonomous Bug Fizing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how
## Task Management
1. **Plan First**: Write plan to
tasks/todo.md" with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to 'tasks/todo.md"
6. **Capture Lessons**: Update
tasks/lessons.md" after corrections
## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimat Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

---

## Project Overview

This project is a **Flutter-based UX prototype** for an MSc UX Design project at Kingston University London.

The product explores a very specific problem space:

> How can a lightweight digital companion support users in the **immediate pre-performance moment** — when they feel nervous, overwhelmed, cognitively overloaded, or stuck in overthinking loops?

Examples of such moments include:
- before a presentation
- before a meeting
- before an interview
- before a date
- before any other short-term high-pressure social or performance situation

This is **not** a therapy app, not a long-term mental health solution, and not a meditation platform in the traditional sense.

The concept focuses only on:
- **acute, in-the-moment support**
- **short interaction windows**
- **minimal cognitive load**
- **structured grounding**
- **friction-aware UX**

The app should help users feel:
- more clear
- more focused
- more grounded
- more in control
- more ready

---

## Core Product Positioning

The core hypothesis behind the project is:

> Existing stress or wellness tools often fail in the exact moment they are needed most, because they assume cognitive capacity, patience, and willingness to engage.

This app should therefore be designed for a user who is:
- already stressed
- easily overwhelmed
- low on attention
- not willing to read much
- not willing to configure anything
- not looking for a “full session”
- in need of immediate support within ~3 minutes

The UX should therefore reduce:
- decisions
- input effort
- navigation complexity
- cognitive load
- ambiguity

And increase:
- clarity
- pacing
- perceived control
- emotional regulation
- readiness for the upcoming event

---

## Build Goal

The goal is to build a **functional prototype in Flutter**, primarily for:
- low-fidelity testing
- iteration after testing
- mid-fidelity refinement
- research demonstrations
- usability walkthroughs

This is **not** a production app.
This is also **not** a final polished high-fidelity product.

The priority is:

1. **Functionality**
2. **Interaction logic**
3. **Testing readiness**
4. **Useful instrumentation / debug data**
5. **Visual design**

Design still matters, but it should support testing rather than slow down development.

---

## Current Development Goal

Build a prototype that can test the current 3 core feature directions that emerged from co-creation.

These features should be implemented as simple but usable interaction flows.

### Current concept features

The prototype currently explores three distinct intervention types:

1. **Sensor-Based Balancing Game**  
   → physical + attentional grounding via phone movement

2. **Voice-Based Thought Offloading**  
   → externalising thoughts into a structured visual system

3. **Time-Based Passive Focus Mode**  
   → minimal, non-interactive calming experience

Detailed specifications, flow constraints, and implementation intent are defined in `FEATURES.md`.  
`FEATURES.md` is the feature source of truth and should be consulted before implementation.

---

## Feature Source of Truth

Use the following files together:

- `CODEX.md` → overall project strategy, product intent, architecture, workflow expectations
- `FEATURES.md` → detailed feature definitions, interaction goals, constraints, and flow logic
- moodboard / visual reference files → visual direction only, secondary to interaction clarity

If there is any ambiguity between implementation assumptions and the feature descriptions, prefer:
1. `FEATURES.md`
2. the research/testing purpose of the prototype
3. minimal, testable functionality over extra complexity

---

## UX Principles

The app must follow these principles:

### 1. Low cognitive load
Interfaces should be easy to grasp in seconds.
No dense text walls.
No complex menus.

### 2. Calm but not sleepy
The product should feel grounding and focused, not generic wellness fluff.

### 3. Guided over open-ended
The app should lead the user through the interaction instead of asking them to figure it out.

### 4. Fast entry
Users should be able to start support in 1–2 taps maximum.

### 5. Short-session logic
The app is designed for an immediate window of use, ideally around **1–3 minutes**.

### 6. Functional first
The app should work reliably and be testable before visual polish is added.

### 7. Modular
Each feature should be easy to adjust, remove, reorder, or swap after testing.

---

## Suggested App Structure

Use a simple structure that supports fast iteration.

### Recommended screens
- **Home / Entry screen**
  - very minimal
  - clear choice of the 3 current support modes/features
  - optionally a short prompt like:
    - “What do you need right now?”
    - “What feels most true right now?”
    - “Choose the fastest support option”

- **Feature Flow Screens**
  - each feature should have its own lightweight flow
  - should be modular and reusable
  - avoid deeply nested navigation

- **End / Reset Screen**
  - simple finish state
  - possibly allow:
    - “done”
    - “restart”
    - “try another mode”

- **Debug / Dev Mode**
  - accessible via hidden tap, long press, or visible dev button
  - should expose metrics useful for testing

---

## Suggested Architecture

Keep architecture lightweight and practical.

Recommended:
- `main.dart`
- `app/`
- `features/`
  - `feature_one/`
  - `feature_two/`
  - `feature_three/`
- `shared/`
  - reusable widgets
  - theme
  - helpers
- `debug/`
  - analytics logger
  - testing overlays
  - event tracker
- `docs/`
  - `CODEX.md`
  - `FEATURES.md`
- `tasks/`
  - `todo.md`
  - `lessons.md`

Use simple state management unless complexity requires more.
Preferred starting point:
- `ValueNotifier`
- `ChangeNotifier`
- or a light Riverpod setup if needed

Do not over-engineer.

---

## Recommended Feature Build Order

To reduce risk and get to a testable prototype quickly, build in this order:

1. **Feature 3 – Time-Based Passive Focus Mode**
   - easiest to implement
   - useful for establishing app shell, timing, session logging, reset/exit patterns

2. **Feature 1 – Sensor-Based Balancing Game**
   - adds device sensor handling
   - tests active distraction / attentional redirection

3. **Feature 2 – Voice-Based Thought Offloading**
   - most complex
   - likely needs voice input, transcript handling, and node visualisation logic

This order should only change if there is a strong architectural reason.

---

## Prototype Fidelity Guidance

This prototype should support two stages:

### Low-Fidelity Testing
Used to evaluate:
- feature logic
- flow structure
- wording
- interaction sequence
- whether the concept makes sense

At this stage:
- visuals can stay simple
- placeholders are okay
- core focus is usability and clarity

### Mid-Fidelity Iteration
After low-fi testing, the app should be easy to refine toward:
- clearer hierarchy
- smoother pacing
- improved transitions
- stronger emotional tone
- better perceived usability

---

## Dev / Debug Mode Requirements

A debug/testing mode is highly desirable.

### Debug mode should capture:
- session start time
- session end time
- total interaction duration
- time spent per screen
- feature selected
- number of taps
- hesitation points if possible
- back navigation events
- skipped steps
- restart events
- completion status

### Optional useful test metrics:
- first interaction latency
  - time from app open to first meaningful input
- total time to completion
- dwell time per step
- rage taps / repeated taps
- aborted sessions
- which feature is most chosen

### Debug mode can include:
- on-screen floating debug panel
- exportable JSON / CSV logs
- local console logging
- timestamped interaction events
- fake participant/session ID input

### Debug mode should ideally support:
- reset logs
- save logs locally
- label sessions manually
  - e.g. `P01_LowFi_Test`
  - `P03_MidFi_Test`

This is important because the app is part of a research and testing process, not just a design exercise.

---

## Suggested Data Model

Keep event tracking simple.

Example event structure:

```json
{
  "sessionId": "P01_LowFi_Test",
  "timestamp": "2026-04-12T21:30:00",
  "screen": "breathing_intro",
  "eventType": "tap",
  "elementId": "start_button",
  "elapsedMs": 1200
}