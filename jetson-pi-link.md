---
component: Jetson Orin Nano ↔ Raspberry Pi 4 link
status: design decision — Ethernet recommended, can be practiced in software before hardware arrives
---

# Jetson Orin Nano ↔ Raspberry Pi 4 Link

## Why this matters

Your v2 architecture note says the Pi and Jetson "communicate over serial or USB." Before wiring anything, it's worth locking down *which* link to actually build around, since it affects both the physical connection and how ROS 2 nodes talk to each other later.

## Options, compared

| Method | How it works | Verdict |
|---|---|---|
| **Ethernet** (direct cable, or via a small switch) | Both boards have built-in Gigabit Ethernet | **Recommended** — fastest, most reliable, and it's exactly the transport ROS 2 uses under the hood regardless of Wi-Fi/Ethernet |
| **Wi-Fi** | Both join the same network | Works, fine for bench testing, but less reliable on a moving vehicle (dropouts, interference) |
| **UART (GPIO pins)** | Direct wired serial, TX↔RX crossed, shared GND | Simple, good as a low-bandwidth backup/status link, but far slower and not how ROS 2 is meant to run |
| **USB-to-USB** | One board acts as a USB serial/network device to the other | Caution: the Jetson Orin Nano Devkit's USB-C port is power-only in most configs, not data/gadget mode — don't plan around this unless the specific board is confirmed to support it |

**Decision:** connect the Pi and Jetson over **Ethernet** (direct cable between them, or both plugged into the same onboard switch as the camera/dashboard/etc.). Keep UART as an optional backup link for simple status signals if you want redundancy later.

## Setting up the Ethernet link (once both boards exist)

1. Connect both to the same network — a direct Ethernet cable between them works too; modern ports auto-sense, no crossover cable needed.
2. On each board, find its IP:
   ```
   hostname -I
   ```
3. Confirm they can see each other — from the Pi, ping the Jetson's IP:
   ```
   ping <jetson_ip>
   ```
   And the reverse from the Jetson.

## UART wiring (optional backup link)

| Jetson Orin Nano pin | Raspberry Pi 4 pin |
|---|---|
| UART_TX | UART_RX |
| UART_RX | UART_TX |
| GND | GND |

Check your exact carrier board's pinout diagram for which header pins are UART_TX/RX — it varies by revision.

```python
import serial
import time

ser = serial.Serial('/dev/ttyAMA0', 115200, timeout=1)  # Pi's UART port

while True:
    ser.write(b"hello from pi\n")
    if ser.in_waiting:
        line = ser.readline().decode('utf-8').strip()
        print("Received:", line)
    time.sleep(1)
```

Mirror this on the Jetson side using `/dev/ttyTHS1` (exact name varies by carrier board). Both sides need `pip install pyserial`.

## Connectivity test — can be done right now, before hardware arrives

This TCP socket echo test confirms a network link works, before adding ROS 2 on top. Practice it between your Mac and the Ubuntu VM today — the logic is identical to Pi↔Jetson.

**Server (later: run on the Jetson):**
```python
import socket

HOST = "0.0.0.0"
PORT = 5005

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    print(f"Listening on port {PORT}...")
    conn, addr = s.accept()
    with conn:
        print(f"Connected by {addr}")
        while True:
            data = conn.recv(1024)
            if not data:
                break
            print(f"Received: {data.decode()}")
            conn.sendall(data)  # echo back
```

**Client (later: run on the Raspberry Pi):**
```python
import socket

PEER_IP = "192.168.1.XX"  # replace with the other board's real IP
PORT = 5005

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((PEER_IP, PORT))
    s.sendall(b"hello")
    data = s.recv(1024)
    print(f"Reply: {data.decode()}")
```

## For the real system: ROS 2 needs no extra code

Once ROS 2 is installed on both boards, you generally won't write this socket code yourself — ROS 2's DDS layer handles discovery and messaging automatically over the network. As long as:
- Both boards are on the same network (the Ethernet link above)
- Both have the same `ROS_DOMAIN_ID` set, e.g. `export ROS_DOMAIN_ID=5` on both

...any node on the Jetson can publish/subscribe to any node on the Pi with zero connection code — just normal publisher/subscriber nodes (e.g., `imu_node` on the Pi publishing a topic, a node on the Jetson subscribing to it).

## Open questions to confirm once hardware is in hand

- Whether the onboard network will go through a dedicated switch or a direct cable between the two boards
- Static vs. DHCP IP assignment for the final robot (static is more predictable for a two-device link)
- Whether UART is worth wiring in as a hardware-independent backup, or skipped entirely in favor of Ethernet-only

## Sources
- General ROS 2 DDS networking behavior (same-network discovery via `ROS_DOMAIN_ID`) — standard ROS 2 documentation knowledge, not vendor-specific.
