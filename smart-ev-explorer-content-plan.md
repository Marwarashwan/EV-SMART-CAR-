---
title: Smart EV Explorer — Content Plan (Manual + Report)
status: living checklist — update as sections get completed
---

# Content Plan: What Goes Where

A working checklist of what belongs in the **User Manual** (for operators/visitors, plain language) versus the **Project Report** (for documentation/academic submission, technical), plus the sensor additions that need to be reflected in both.

---

## 1. User Manual (`smart-ev-explorer-user-manual.md`)

Audience: students/visitors at a demo, and whoever operates the finished buggy. Plain language throughout.

| # | Section | Status | Notes / what's still needed |
|---|---|---|---|
| 1 | What Is the Smart EV Explorer? | ✅ Done | — |
| 2 | Meet the Robot (sensor tour + analogies) | ✅ Done | Needs update once battery + environmental sensors are added (see §3 below) |
| 3 | How It All Works Together | ✅ Done | — |
| 4 | Operating the Smart EV Explorer (power on/off, dashboard, e-stop) | ⚠️ Partial | Shutdown steps and dashboard description are still generic — confirm against the real build once software/dashboard is finalized |
| 5 | The Mechanical Build | ⚠️ Draft | Based on the kit's documented parts — confirm which parts/fixes match the actual buggy |
| 6 | Behind the Scenes (power flow, ROS 2, sensor-computer mapping) | ✅ Done | Update sensor-computer table once battery/environmental nodes are placed |
| 7 | Troubleshooting & FAQ | ⚠️ Partial | Currently generic placeholders — replace with real observed issues as they come up during testing |
| 8 | Glossary | ✅ Done | Add entries for new terms as sensors are added (e.g., "State of Charge," "I2C") |
| — | **New: Electrical/Wiring overview (plain language)** | ⬜ To do | A simple "how power gets from the battery to everything" section, parallel to the mechanical section |
| — | **New: Battery & Environmental sensor additions (plain language)** | ⬜ To do | See §3 below |

---

## 2. Project Report (`smart-ev-explorer-report-frontmatter.md` + supporting docs)

Audience: technical/academic reviewers. Full detail, standard report structure.

| # | Section | Status | Notes / what's still needed |
|---|---|---|---|
| 1 | Abstract | ✅ Done | — |
| 2 | Introduction | ✅ Done | — |
| 3 | Problem Statement | ✅ Done | — |
| 4 | Objectives | ✅ Done | — |
| 5 | Scope | ✅ Done | — |
| 6 | Literature Review / Related Work | ⬜ To do | Optional — only if the report format requires comparing to similar platforms |
| 7 | System Architecture (Jetson + Pi, ROS 2, TF2) | ✅ Done (as separate docs) | Currently split across `jetson-pi-link-and-mac-setup.md`, `smart-ev-explorer-tf-coordinate-frames.md`, `smart-ev-explorer-ros-nodes-packages.md` — merge into report body when finalizing |
| 8 | Mechanical Design | ⚠️ Draft | Same content as manual §5, but can include more technical detail (tolerances, materials, defect analysis) than the manual version |
| 9 | Electrical Design | ⬜ To do | 48V distribution, fusing, e-stop/relay logic, voltage regulation — needs a dedicated write-up (schematic from `software/Schematic/EV_CU` can support this) |
| 10 | Sensor Integration (5 core sensors) | ✅ Done (as separate docs) | Camera, LiDAR, IMU, GPS, ultrasonic — covered in ROS nodes/packages doc and sensor-specific docs |
| 11 | Sensor Additions (battery + environmental) | ⬜ To do | See §3 below — needs to move from "design plan" to a proper report section once implemented |
| 12 | Implementation & Testing | ⬜ To do | What was actually built/verified (Task 1.1–1.8 sign-off results, camera verification, TF tree confirmation) |
| 13 | Results | ⬜ To do | Pending actual testing outcomes |
| 14 | Conclusion & Future Work | ⬜ To do | Pending project completion |
| 15 | References | ⬜ To do | ROS 2 docs, datasheets (ZED, RPLIDAR, WT901, INA219/INA226, BME280), REP-103/REP-105 |

---

## 3. Sensor Additions: Battery Monitoring + Environmental Sensor

Status across both documents — these need the same underlying content, written at two different levels of detail.

| Task | Manual (plain language) | Report (technical) |
|---|---|---|
| Describe what the sensor does | ⬜ Add to "Meet the Robot" table — e.g., "Battery sensor: a fuel gauge for the robot" | ✅ Already covered in `smart-ev-explorer-battery-env-sensor.md` |
| Hardware/wiring | Not needed in manual (operators don't need wiring diagrams) | ✅ Covered — INA219/INA226 on 48V bus, BME280 shared I2C bus |
| Software/ROS 2 node design | Not needed in manual | ✅ Covered — `battery_monitor_node` in `motor_control_pkg`, `env_sensor_node` in `localization_pkg` |
| Dashboard integration | ⬜ Add to "Reading the Dashboard" section once battery % and temp/humidity are shown on-screen | ⬜ Document once `rosbridge_suite` wiring to the dashboard is implemented |
| Physical installation | ⬜ Note where the sensors physically sit on the buggy, once mounted | ⬜ Add mounting location + any TF frame offset, same pattern as the 5 core sensors |
| Safety behavior (low battery handling) | ⬜ Add to "Troubleshooting & FAQ" — what happens / what to do if battery runs low | ⬜ Document the soft-shutdown/estop-trigger threshold once implemented |
| Testing/verification | Not needed in manual | ⬜ Confirm `/battery_state` and `/environment` topics publish correctly once wired up |

**Outstanding before these can move from "design plan" to "implemented":**
1. Physically wire the INA219/INA226 inline on the 48V bus and the BME280 on the shared I2C bus.
2. Write and test the two ROS 2 nodes (`battery_monitor_node`, `env_sensor_node`).
3. Confirm both topics (`/battery_state`, `/environment`) publish correctly (`ros2 topic echo`).
4. Decide and implement the low-battery safety threshold/behavior.
5. Wire both topics into the dashboard via `rosbridge_suite`.
6. Once confirmed working, update both the manual and report sections marked ⬜ above.

---

## How to Use This File

- Treat each ⬜/⚠️ row as a task — update the status column as work completes.
- When a section moves from ⬜/⚠️ to ✅, pull the actual content into the corresponding manual or report file.
- This file itself doesn't need to be part of the final manual or report — it's a working tracker.
