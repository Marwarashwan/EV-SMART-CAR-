---
component: WitMotion WT901 IMU
status: research complete — can be tested now, no Pi/Jetson required
---

# WitMotion WT901 IMU
A 9-axis IMU (accelerometer + gyroscope + magnetometer) that outputs orientation (roll/pitch/yaw), angular velocity, and acceleration. WitMotion sells it with either a USB dongle (easiest for a first test) or bare TTL pins (for wiring directly to a microcontroller/Pi later).

## Wiring (for the real build, later)

| WT901 pin | Connects to |
|---|---|
| VCC | 5V (or 3.3V, check your exact module variant) |
| GND | Common GND |
| TX | Receiver's RX |
| RX | Receiver's TX |

In your architecture, this goes to the Raspberry Pi 4's serial pins (UART), not the Jetson.

## Protocol

WitMotion uses their own lightweight serial protocol — fixed-length packets, each starting with a header byte, containing an ID for which data type it carries (angle, acceleration, gyro, etc.), the data itself, and a checksum. Default baud rate is typically 9600 (configurable). Full protocol detail: [Unified Witmotion communication protocol](https://elettrascicomp.github.io/witmotion_IMU_QT/d6/de1/witmotion_protocol.html).

## How to test it right now (via USB dongle, on your Mac)

1. Plug in the USB dongle — macOS should recognize it as a serial device (check with `ls /dev/tty.*` in Terminal after plugging in; look for something like `/dev/tty.usbserial-XXXX`)
2. Install a Python library to read it. Two solid options:
   - **[witmotion (PyPI/readthedocs)](https://witmotion.readthedocs.io/en/latest/index.html)** — documented Python interface, works over serial
   - **[pywitmotion (askuric)](https://github.com/askuric/pywitmotion)** — a pip package specifically for parsing WT901/BWT901CL data
   - WitMotion's own **[Python SDK quick start](https://wit-motion.gitbook.io/witmotion-sdk/wit-standard-protocol/sdk/python_sdk-quick-start)** is also worth checking directly from the manufacturer
3. Install with pip (example):
   ```
   pip install witmotion
   ```
4. Run a short script to open the serial port and print live orientation data (the library's own docs have a working example — follow their quick-start exactly, since baud rate and port name need to match your dongle).

## What this gets you

- A first real sensor-reading pipeline, end to end, before any other hardware shows up
- A natural first ROS node to write later: wrap this same serial-read logic into `localization_pkg/imu_node`
- Confidence that the IMU itself works correctly, isolated from any Pi/Jetson wiring issues later — if something's wrong with IMU data after it's wired into the full system, you'll already know the sensor itself is good

## Open questions to confirm once you have the actual unit in hand

- Exact voltage: 3.3V or 5V variant (check the silkscreen/datasheet on your specific module)
- Default baud rate shipped on your unit (WitMotion units can ship pre-configured differently)
- Whether your purchased kit included the USB dongle or only bare TTL pins

## Sources
- [pywitmotion (GitHub)](https://github.com/askuric/pywitmotion)
- [witmotion Python Interface (readthedocs)](https://witmotion.readthedocs.io/en/latest/index.html)
- [Unified Witmotion communication protocol](https://elettrascicomp.github.io/witmotion_IMU_QT/d6/de1/witmotion_protocol.html)
- [WitMotion Python SDK Quick Start](https://wit-motion.gitbook.io/witmotion-sdk/wit-standard-protocol/sdk/python_sdk-quick-start)
- [witmotion GitHub topic page](https://github.com/topics/witmotion)
