# Mini System Manager (Revidyne)

**Repository:** `github.com/elijah286/mini-system-manager`  
**Purpose:** A simple, readable LabVIEW-based “mini system manager” for connecting to **Revidyne** educational hardware systems (available via **revidyne.com**).

Revidyne builds small, functional, desktop-scale models designed to help educators teach engineering and programming concepts using real “code + electronics + physical system” workflows. Examples include modules like a solar tracker (ReviSol), a wind turbine (ReviWin), and a small power plant model (ReviGen), all controllable over USB.  
Learn more about the hardware at **revidyne.com**.

---

## What this software does

This project provides a **Queued Message Handler (QMH)** application focused on:

- **Device connectivity**
  - Connect to Revidyne hardware over USB (string/command-style communication).
- **Command discovery**
  - Query a connected device for its supported command set.
- **Interactive test console**
  - Send commands, receive responses/data, and validate behavior during development or labs.
- **Curriculum + exercises integration**
  - Serve pre-written curriculum materials and related exercises.
  - Help learners understand **which devices are required** and **which devices are compatible** with a given lesson plan.

The code is intentionally **simple and readable** to model best practices and make it approachable for students and educators.

---

## Installation & Setup

This project is intentionally lightweight—there’s no installer.

### Requirements
- **LabVIEW 2020 or later**
- **NI-VISA** (required for device communications)

### Steps
1. Download (or clone) this repository:
   ```bash
   git clone https://github.com/elijah286/mini-system-manager.git

---

## Supported Revidyne systems (examples)

Revidyne offers multiple small systems that connect to a PC via USB and can be monitored/controlled with string-based commands. Examples include:

- **ReviSol** — solar tracker with a photovoltaic panel and stepper motor; supports solar tracking algorithms and IV curve tracing concepts.
- **ReviWin** — wind turbine model with directional control and interrupt-driven wind-speed measurement concepts.
- **ReviGen** — small power plant model with motor/generator coupling, PWM control, output power calculations, and PID control concepts.
- **ReviGrid** — a collection of power grid models connected via a case hub to explore smart-grid strategies and model interactions.

(See **revidyne.com** for the current set of models and details.)

---

## Architecture

This application uses a classic **Queued Message Handler (QMH)** style:

- A UI/message loop enqueues actions
- A worker/handler loop processes messages deterministically
- State and device I/O are kept straightforward to support teaching and maintainability

---

## Screenshot: Main Block Diagram (QMH)

<img width="1489" height="777" alt="Screenshot 2026-02-09 at 5 09 49 PM" src="https://github.com/user-attachments/assets/5bf8a3d0-2be4-4805-aef1-b7e424dd08a4" />

## VI File Browser

Browse front panel and block diagram snapshots for every VI in this project:
**[Open VI Browser →](https://elijah286.github.io/mini-system-manager/vi-snapshots/)**

<details>
<summary><strong>All VIs & Controls (42 files)</strong></summary>

#### Root

| File | Type |
|------|------|
| [Controller Commands.ctl](https://elijah286.github.io/mini-system-manager/vi-snapshots/Controller%20Commands.ctl.html) | CTL |
| [Curriculum Launcher.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum%20Launcher.vi.html) | VI |
| [Find Curriculum.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Find%20Curriculum.vi.html) | VI |
| [Graph Popup.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Graph%20Popup.vi.html) | VI |
| [main.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/main.vi.html) | VI |
| [Simple Solar Tracker v4.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Simple%20Solar%20Tracker%20v4.vi.html) | VI |
| [Status String Update.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Status%20String%20Update.vi.html) | VI |

#### Curriculum / Generator API

| File | Type |
|------|------|
| [Generator Driver Template 1.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/Generator%20Driver%20Template%201.vi.html) | VI |
| [Generator Driver Template 2.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/Generator%20Driver%20Template%202.vi.html) | VI |
| [Generator Driver Template 3.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/Generator%20Driver%20Template%203.vi.html) | VI |
| [Generator Driver Template 4.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/Generator%20Driver%20Template%204.vi.html) | VI |
| [Generator Driver Template 5.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/Generator%20Driver%20Template%205.vi.html) | VI |

#### Curriculum / Generator API / subVIs

| File | Type |
|------|------|
| [Demo PID Control.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Demo/Demo%20PID%20Control.vi.html) | VI |
| [Default Instrument Setup.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Private/Default%20Instrument%20Setup.vi.html) | VI |
| [Close.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Close.vi.html) | VI |
| [Initialize.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Initialize.vi.html) | VI |
| [VI Tree.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/VI%20Tree.vi.html) | VI |
| [Init.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Action-Status/Init.vi.html) | VI |
| [Motor Off.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Action-Status/Motor%20Off.vi.html) | VI |
| [Motor On.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Action-Status/Motor%20On.vi.html) | VI |
| [Set Load.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Configure/Set%20Load.vi.html) | VI |
| [Set Speed.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Configure/Set%20Speed.vi.html) | VI |
| [Get KW.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Data/Get%20KW.vi.html) | VI |
| [Get Value.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Data/Get%20Value.vi.html) | VI |
| [Error Query.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Utility/Error%20Query.vi.html) | VI |
| [Reset.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Utility/Reset.vi.html) | VI |
| [Revision Query.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Utility/Revision%20Query.vi.html) | VI |
| [Self-Test.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20API/subVIs/Public/Utility/Self-Test.vi.html) | VI |

#### Curriculum / Generator Lessons

| File | Type |
|------|------|
| [Generator Lesson 1.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%201.vi.html) | VI |
| [Generator Lesson 2.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%202.vi.html) | VI |
| [Generator Lesson 3.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%203.vi.html) | VI |
| [Generator Lesson 4.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%204.vi.html) | VI |
| [Generator Lesson 5.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%205.vi.html) | VI |
| [Generator Lesson 6.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%206.vi.html) | VI |
| [Generator Lesson 7.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/Generator%20Lesson%207.vi.html) | VI |
| [balance grid.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/subVIs/balance%20grid.vi.html) | VI |
| [Command with Return Value.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/subVIs/Command%20with%20Return%20Value.vi.html) | VI |
| [Confirm USB Devices and IO.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/subVIs/Confirm%20USB%20Devices%20and%20IO.vi.html) | VI |
| [Get All Values.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/subVIs/Get%20All%20Values.vi.html) | VI |
| [USB Device Filter.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Generator%20Lessons/subVIs/USB%20Device%20Filter.vi.html) | VI |

#### Curriculum / Main Power Grid

| File | Type |
|------|------|
| [Main Power Grid.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Main%20Power%20Grid/Main%20Power%20Grid.vi.html) | VI |

#### Curriculum / Solar Lessons

| File | Type |
|------|------|
| [Solar Example.vi](https://elijah286.github.io/mini-system-manager/vi-snapshots/Curriculum/Solar%20Lessons/Solar%20Example.vi.html) | VI |

</details>

---

## Getting started

1. **Install LabVIEW** (version/tooling appropriate for the project contents).
2. **Clone the repo**
   ```bash
   git clone https://github.com/elijah286/mini-system-manager.git
  ```

## CI pipeline

This repository now includes GitHub Actions modeled on the Windows-container workflows in `ni/labview-for-containers`:

- **MassCompile - Windows Container**: mass compiles the repository on pull requests and pushes to `main`
- **Run VI Analyzer - Windows Container**: runs a starter VI Analyzer ruleset and uploads the text report as an artifact
- **VIDiff Report - Windows Container**: generates HTML diffs for changed `.vi` and `.ctl` files in pull requests
- **Deploy VIDiff Reports**: publishes VIDiff HTML reports to GitHub Pages and comments on the pull request with links

The CI workflows pull a pre-baked LabVIEW image from GitHub Container Registry (GHCR): `ghcr.io/elijah286/mini-system-manager-labview:2026`.

This repo keeps the image definition in source control and the built image in GHCR:

- Dockerfile in repo: `.github/docker/labview-ci.Dockerfile`
- Build/publish workflow: `.github/workflows/build-labview-image.yml`
- Published package location: repository **Packages** tab in GitHub

### Rebuilding the CI image

1. Run the `Build LabVIEW CI Image` workflow from Actions.
2. Optionally set `labview_tag` in workflow dispatch input (defaults to `2026`).
3. Check the workflow summary for the pushed tags and digest.

The build workflow runs on changes to the Dockerfile path and monthly on schedule, and always uses `windows-2022`.

If you need to pin a different LabVIEW version, update `LABVIEW_CONTAINER_IMAGE` in workflow files under `.github/workflows/`, then rebuild and publish the corresponding image tag.

The starter VI Analyzer configuration is in `.github/labview/via-configs/via-config-default.viancfg`. You should expect to tune that ruleset once you see the first CI results for this codebase.

<!-- labview-ci:dashboard -->
## LabVIEW CI

[![LabVIEW CI dashboard](https://img.shields.io/badge/LabVIEW%20CI-dashboard-2ea44f)](https://elijah286.github.io/mini-system-manager/)

LabVIEW CI runs on every pull request. See the [**CI dashboard**](https://elijah286.github.io/mini-system-manager/) for build status, VI Analyzer results, VI diffs, and mass-compile reports.
