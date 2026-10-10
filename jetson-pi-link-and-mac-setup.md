---
component: Jetson ↔ Pi communication + Ubuntu/ROS 2 setup on Mac
status: design decision + install guide — Ethernet link recommended; Ubuntu VM via UTM for Apple Silicon
---

# Jetson Orin Nano ↔ Raspberry Pi 4 Communication + Setting Up Linux/ROS 2 on Your Mac

## Part 1 — How the Jetson and Pi talk to each other

### Options, compared

| Method | How it works | Verdict |
|---|---|---|
| **Ethernet** (direct cable, or via a small switch) | Both boards have built-in Gigabit Ethernet | **Recommended** — fastest, most reliable, and it's exactly the transport ROS 2 uses under the hood regardless of Wi-Fi/Ethernet |
| **Wi-Fi** | Both join the same network | Works, fine for bench testing, but less reliable on a moving vehicle (dropouts, interference) |
| **UART (GPIO pins)** | Direct wired serial, TX↔RX crossed, shared GND | Simple, good as a low-bandwidth backup/status link, but far slower and not how ROS 2 is meant to run |
| **USB-to-USB** | One board acts as a USB serial/network device to the other | Caution: the Jetson Orin Nano Devkit's USB-C port is power-only in most configs, not data/gadget mode — don't plan around this unless confirmed |

**Decision:** connect the Pi and Jetson over **Ethernet** — direct cable between them, or both plugged into the same onboard switch alongside the camera/dashboard/etc. Keep UART as an optional backup link for simple status signals only.

### Setting up the Ethernet link (once both boards exist)

1. Connect both to the same network — a direct Ethernet cable works too; modern ports auto-sense, no crossover cable needed.
2. On each board, find its IP:
   ```
   hostname -I
   ```
3. Confirm they can see each other — from the Pi, ping the Jetson's IP:
   ```
   ping <jetson_ip>
   ```
   And the reverse from the Jetson.

### UART wiring (optional backup link)

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

### Connectivity test — can be done right now, before hardware arrives

This TCP socket echo test confirms a network link works, before adding ROS 2 on top. You can practice it between your Mac and the Ubuntu VM today (Part 2 below) — the logic is identical to Pi↔Jetson.

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

### For the real system: ROS 2 needs no extra connection code

Once ROS 2 is installed on both boards, you won't write this socket code yourself for normal operation — ROS 2's DDS layer handles discovery and messaging automatically over the network. As long as:
- Both boards are on the same network (the Ethernet link above)
- Both have the same `ROS_DOMAIN_ID` set, e.g. `export ROS_DOMAIN_ID=5` on both

...any node on the Jetson can publish/subscribe to any node on the Pi with zero connection code — just normal publisher/subscriber nodes (e.g., `imu_node` on the Pi publishing a topic, a node on the Jetson subscribing to it).

---

## Part 2 — Installing Linux + ROS 2 on your Mac

Your Mac is Apple Silicon (ARM64), and NVIDIA's Jetson flashing tool (SDK Manager) only runs on Ubuntu x86/ARM — not macOS directly. The standard path is: run Ubuntu inside a VM on your Mac using **UTM** (free, built for Apple Silicon), then install ROS 2 inside that VM.

### Step 1 — Install UTM

1. Go to [mac.getutm.app](https://mac.getutm.app/) or install via Homebrew:
   ```
   brew install --cask utm
   ```
2. Open UTM once installed to confirm it launches.

### Step 2 — Download an Ubuntu ARM64 image

1. Go to [ubuntu.com/download/server](https://ubuntu.com/download/server) (or the desktop edition if you want a GUI) and download the **ARM64** `.iso` — not the x86/amd64 version, since Apple Silicon needs ARM.
2. Ubuntu 22.04 LTS ("Jammy") is the safest choice — it has first-class ROS 2 Humble support, which is the most widely used current LTS ROS 2 release.

### Step 3 — Create the VM in UTM

1. Open UTM → **Create a New Virtual Machine**
2. Choose **Virtualize** (not Emulate — virtualization is far faster on Apple Silicon)
3. Choose **Linux**
4. Point it at the Ubuntu ARM64 `.iso` you downloaded
5. Allocate resources — give it at least:
   - 4 GB RAM (8 GB+ is more comfortable for ROS 2 + building workspaces)
   - 40+ GB disk
   - Multiple CPU cores if your Mac has them to spare
6. Finish the wizard and boot the VM — it will start the Ubuntu installer

### Step 4 — Install Ubuntu inside the VM

1. Follow the on-screen Ubuntu installer (keyboard layout, username/password, disk partitioning — default/guided partitioning is fine)
2. Once installed, reboot the VM (UTM may ask you to remove the install media/iso from the VM's drive — do that so it boots from disk, not the installer again)
3. Log in, then update the system:
   ```
   sudo apt update && sudo apt upgrade -y
   ```

### Step 5 — Install ROS 2 (Humble, on Ubuntu 22.04)

1. Set locale (ROS 2 install guides require UTF-8):
   ```
   locale  # check current settings
   sudo apt update && sudo apt install locales
   sudo locale-gen en_US en_US.UTF-8
   sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
   export LANG=en_US.UTF-8
   ```
2. Enable the Ubuntu Universe repository:
   ```
   sudo apt install software-properties-common
   sudo add-apt-repository universe
   ```
3. Add the ROS 2 GPG key and repository:
   ```
   sudo apt update && sudo apt install curl -y
   sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
   ```
4. Install ROS 2 Humble (desktop version includes RViz, demos, tutorials — recommended over the bare "ros-base" for learning):
   ```
   sudo apt update
   sudo apt install ros-humble-desktop -y
   ```
5. Source it in your shell (add to `~/.bashrc` so it loads every terminal session):
   ```
   echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
   source ~/.bashrc
   ```
6. Install developer tools (needed for building your own packages/workspace):
   ```
   sudo apt install python3-colcon-common-extensions python3-rosdep -y
   sudo rosdep init
   rosdep update
   ```

### Step 6 — Verify the install

Run ROS 2's built-in demo talker/listener in two terminals to confirm everything works:

**Terminal 1:**
```
ros2 run demo_nodes_cpp talker
```

**Terminal 2:**
```
ros2 run demo_nodes_cpp listener
```

If the listener prints messages being published by the talker, ROS 2 is correctly installed.

### Step 7 — Create your workspace

```
mkdir -p ~/your_ws/src
cd ~/your_ws
colcon build
echo "source ~/your_ws/install/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

This is the `your_ws/src/` folder referenced in your package plan (`motor_control_pkg`, `perception_pkg`, `localization_pkg`, `dashboard_pkg`) — ready for you to start adding packages into.

## Notes

- This VM is for **development and the NVIDIA SDK Manager flashing tool** (needed later to flash the Jetson itself) — it is not the Jetson's own OS. The Jetson runs its own flashed Ubuntu/JetPack image once hardware arrives; the Raspberry Pi 4 runs its own Ubuntu or Raspberry Pi OS with ROS 2 installed the same way as above.
- If UTM feels slow, confirm you selected **Virtualize** rather than **Emulate** when creating the VM — emulating x86 on Apple Silicon is drastically slower and is not what you want here, since you downloaded the ARM64 Ubuntu image specifically to avoid that.
- ROS 2 Humble pairs with Ubuntu 22.04 specifically — if you instead install Ubuntu 24.04, use **ROS 2 Jazzy** instead and swap `humble` for `jazzy` in all commands above.

## Sources
- [UTM for Mac](https://mac.getutm.app/)
- [Ubuntu Server/Desktop downloads](https://ubuntu.com/download/server)
- [ROS 2 Humble installation (Ubuntu) — official docs](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html)
