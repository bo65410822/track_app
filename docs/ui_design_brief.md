# TrackLog (轨迹记) — UI Design Brief

> Hand this document to a UI design AI/designer. It describes the product, the
> visual direction, and every screen to design. Output expected: high-fidelity
> mobile UI mockups (plus color/typography annotations if possible).

---

## 1. Product Overview

- App name: **TrackLog (轨迹记)**
- Platform: **Android**, portrait orientation, ~1080x2340 px
- Purpose: A **GPS activity-tracking app**. When the user starts recording, the
  app draws their walking/cycling/running route on a map in **real time**,
  calculates **total distance and duration**, and lets them **save and review**
  past tracks.
- Target users: everyday people who run, cycle, or hike.
- UI language: **Simplified Chinese** labels.

## 2. Visual Direction

- Modern, clean, minimal, with a **sporty feel**.
- Follow **Material Design 3 (Material You)**.
- **Light theme**, with one **accent color** (teal or energetic green) to convey
  a sporty vibe.
- Generous white space; rounded-corner cards; soft shadows.
- Key metrics (**distance, duration**) must be **large, bold, and clear**.
- Clear data visualization; readable numbers.

Style keywords: `clean, modern, Material You, health & fitness app, light theme,
generous white space, rounded-corner cards, soft shadows, clear data
visualization, teal accent, large readable numbers`.

## 3. Screens to Design

### Screen 1 — Map Home (most important)

- The whole screen is a map (use a placeholder map).
- Top: app name **"轨迹记"**; a **history** entry icon in the top-right corner.
- A **semi-transparent info card** near the top overlaying the map, prominently
  showing two metrics:
  - distance (e.g. `1.85 公里`)
  - duration (e.g. `00:12:35`)
  - numbers large and clear.
- **Bottom center: a prominent primary button** to **"开始记录" (Start)**.
  While recording it becomes **"停止记录" (Stop)**, turns **red**, with a clear
  "recording in progress" visual cue.
- **Bottom right: a smaller circular** "locate / back to current position"
  button.
- Provide **two states**: "not recording" and "recording in progress".

### Screen 2 — History List

- Top title **"历史记录"** with a back button.
- A list of saved tracks; each item is a **card** showing:
  - distance (km)
  - duration
  - recorded date-time (e.g. `2026-10-20 15:30`)
- Each item is **tappable** to open details; make it visually feel tappable.
- Optionally add a small **route thumbnail** or an activity icon per item.
- Also design an **empty state** ("暂无记录").

### Screen 3 — Track Detail

- Top title **"轨迹详情"** with a back button.
- Body: a map with **one clearly visible colored polyline** drawing the full
  route, plus **distinct start and end markers**.
- A **stats card** overlaying the map (top or bottom) showing: distance,
  duration, recorded time.
- Keep the style consistent with the home screen.

## 4. Deliverable Requirements

- One high-fidelity mockup per screen (Map Home needs both states).
- Keep a consistent design system across all screens (colors, spacing,
  typography, components).
- If possible, **annotate** the main **color hex values** and **font sizes** —
  this makes faithful implementation in code much easier.

## 5. Optional Reference

If a visual reference helps, aim for the polish level of fitness/tracking apps
such as **Strava / Keep / 悦跑圈** (clean maps, bold stats, minimal chrome).
