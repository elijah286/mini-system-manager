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


## Getting started

1. **Install LabVIEW** (version/tooling appropriate for the project contents).
2. **Clone the repo**
   ```bash
   git clone https://github.com/elijah286/mini-system-manager.git
