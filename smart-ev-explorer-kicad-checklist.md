# Smart EV Explorer — KiCad Build Checklist

Use this as a working checklist while you build the schematic in KiCad. Organized as three hierarchical sheets, matching the sections of the assignment.

---

## Project setup

- [ ] New project: `smart_ev_explorer`
- [ ] Root schematic → 3 hierarchical sheets:
  - `Power_and_Ground`
  - `Controllers_and_Sensors`
  - `Relay_Safety`
- [ ] Add hierarchical labels/pins between sheets for: `+48V`, `+12V`, `+5V`, `GND`, and any signal that crosses sheets (e.g. `RELAY_CTRL`)

---

## Sheet 1 — Power_and_Ground

**Symbols to place** (search these names in the symbol chooser):
| Component | KiCad symbol | Library |
|---|---|---|
| 48V battery | `Battery_Cell` (x several, series) or `Battery` | Device |
| Master switch | `SW_SPST` | Switch |
| Fuse | `Fuse` | Device |
| Regulator 1 (48→12V) | `Regulator_Linear:` generic, or a plain rectangle symbol you label "48→12V" | Regulator_Linear / custom |
| Regulator 2 (48→5V) | Same approach, label "48→5V" | custom |

**Nets/labels to add:**
- `+48V` — from battery+ through switch/fuse to both regulator inputs
- `+12V` — Reg 1 output
- `+5V` — Reg 2 output
- `GND` — global label, tie battery−, both regulator grounds, and every downstream ground pin to this

**Tip:** Use KiCad's **global labels** (not just local net labels) for `GND`, `+12V`, `+5V` if they need to be shared across sheets without drawing wires between sheets.

**ERC checks to expect:** unconnected pin warnings on regulator symbols if you used a generic 2/3-pin part — assign pin types (input/output/power) correctly or the checker will flag false errors.

---

## Sheet 2 — Controllers_and_Sensors

**Symbols to place:**
| Component | Approach |
|---|---|
| Jetson Orin Nano/NX | No native symbol — create a custom rectangle symbol with labeled pins: `PWR_12V`, `GND`, `USB_D+`, `USB_D-` (or just one `USB` bus pin) |
| Arduino Mega 2560 | Search `Arduino_UNO_R3` as a rough stand-in, or make a custom block with pins: `5V`, `GND`, `RX1`, `TX1`, `D7`, `D8`, `D22` (or your chosen pins) |
| RPLIDAR S3 | Custom block: `USB` (power+data combined), `GND` |
| WT901 IMU | Custom block: `VCC`, `GND`, `TX`, `RX` |
| Ultrasonic sensor | Custom block: `VCC`, `GND`, `TRIG`, `ECHO` |
| Divider resistors | `R` (x2) — 1kΩ and 2kΩ | Device |

**Connections to wire:**
- Jetson `PWR_12V` → `+12V` net; Jetson `GND` → `GND` net
- Arduino `5V` → `+5V` net; Arduino `GND` → `GND` net
- Jetson USB ↔ Arduino USB/UART (label as `JETSON_ARDUINO_LINK`)
- Jetson USB ↔ RPLIDAR USB
- IMU `TX` → Arduino `RX1`; IMU `RX` → Arduino `TX1`; IMU `VCC` → `+5V`; IMU `GND` → `GND`
- Ultrasonic `VCC` → `+5V`; `GND` → `GND`; `TRIG` → Arduino `D7`
- Ultrasonic `ECHO` → R1 (1kΩ) → node → Arduino `D8`; node → R2 (2kΩ) → `GND`
  - Label the midpoint net `ECHO_3V3` so it's easy to verify in ERC/netlist

---

## Sheet 3 — Relay_Safety

**Symbols to place:**
| Component | KiCad symbol | Library |
|---|---|---|
| Relay | `Relay_SPDT` (or `Relay_DPDT` if modeling both channels) | Relay |
| Relay module block (optional wrapper) | Custom rectangle labeled "2-Channel Relay Module" with pins `VCC`, `GND`, `IN1`, `COM`, `NO` |

**Connections to wire:**
- Relay `VCC` → `+5V`; `GND` → `GND`
- Relay `IN1` → Arduino `D22` (control line — label net `RELAY_CTRL`)
- Relay `COM` → ignition/motor supply line (label `IGN_SUPPLY`)
- Relay `NO` → ignition/motor load line (label `IGN_SWITCHED`)
- Keep this high-voltage/motor side visually separated (e.g., a boxed-off area or a different color wire) from the 5V logic side, since it's a different voltage domain

---

## Before exporting

- [ ] Run **ERC** (Inspect → Electrical Rules Checker) and resolve all errors; warnings on custom symbols with unassigned pin types are common — fix by editing pin electrical type
- [ ] Add a title block: File → Page Settings — fill in Title, Date, Revision, Your name
- [ ] Add a legend/notes text box listing net-color conventions if you colored wires
- [ ] File → Plot → choose PDF (or SVG/PNG) for the version you'll submit or post

---

## Notes
- Custom symbols for the Jetson, Arduino, RPLIDAR, IMU, and ultrasonic sensor are expected — KiCad doesn't ship exact dev-board symbols, and using simple labeled rectangles for board-level (not chip-level) schematics is standard practice.
- If you want footprints too (for eventually laying out a PCB), you'd need to assign footprints per symbol — not required for a schematic-only submission.
