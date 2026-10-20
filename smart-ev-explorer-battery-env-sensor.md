---
component: Battery monitoring (SoC) + environmental sensor addition
status: design plan — low-cost, shared I2C bus, slots into existing packages
---

# Smart EV Explorer — Battery Monitoring & Environmental Sensor Addition

Two low-cost, low-integration-risk additions: battery monitoring (safety-focused) and an environmental sensor (sensing-focused). Both are I2C devices that can share a single bus on the Raspberry Pi, and both slot into packages already planned (`motor_control_pkg`, `localization_pkg`) rather than needing a new one.

## 1. Battery Monitoring (State of Charge)

**Hardware:** An INA219 (or INA226 for higher precision) voltage/current sensor module — cheap, I2C-based, sits inline on the 48V bus between the battery and the fuse/e-stop.

**Wiring**

| INA219 pin | Connects to |
|---|---|
| VIN+ / VIN- | In-line on the 48V bus (current flows through the sensor) |
| SDA / SCL | Raspberry Pi's I2C pins (GPIO 2/3) |
| VCC | Pi's 3.3V |
| GND | Common GND |

**Node:** `battery_monitor_node` in `motor_control_pkg` — fits naturally alongside the e-stop logic, since low battery should trigger a safe state.

- Reads voltage + current over I2C (`smbus2` or `Adafruit_INA219` Python library)
- Publishes `/battery_state` (`sensor_msgs/BatteryState` — a standard ROS 2 message type with fields for voltage, current, percentage, and a `POWER_SUPPLY_STATUS` enum)
- Can also publish to `/estop_status` or trigger a soft shutdown if voltage drops below a safe threshold

**Dashboard tie-in:** since `rosbridge_suite` is already planned, `/battery_state` becomes just another topic the dashboard subscribes to — a battery icon/percentage, no extra plumbing needed.

## 2. Environmental Sensor (Temp/Humidity)

**Hardware:** A DHT22 (cheap, decent accuracy) or BME280 (better — also gives barometric pressure, useful for altitude). BME280 is I2C like the INA219, so it can share the same bus.

**Wiring (BME280)**

| BME280 pin | Connects to |
|---|---|
| SDA / SCL | Same I2C bus as the battery sensor (shared bus, different address) |
| VCC | 3.3V |
| GND | Common GND |

**Node:** `env_sensor_node` — fits best in `localization_pkg` alongside IMU/GPS, since it's another "read a sensor, publish a topic" node on the Pi.

- Publishes `/environment` — needs a small custom message (`float32 temperature`, `float32 humidity`, optionally `float32 pressure`), since there's no standard ROS 2 message for this combo
- Low-rate publishing (e.g., 1 Hz) is plenty — no need to flood the topic

## Why Both Are Easy Wins

- Both are I2C — the battery and environmental sensors can share the same two wires (SDA/SCL), just different I2C addresses: one bus, two cheap sensors, two small Python nodes
- Neither touches existing motor control, perception, or safety logic — pure additions
- Both slot into packages already planned (`motor_control_pkg`, `localization_pkg`) — no new package needed
