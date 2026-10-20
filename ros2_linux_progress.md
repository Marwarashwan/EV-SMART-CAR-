# Linux + ROS 2 + Gazebo Setup: Progress Log

**Owner:** Marwa · **Machine:** MacBook Pro (Apple M2, 16 GB RAM) · **Last updated:** 20 Oct 2026

---

## 1. What I have now

| Component | Details | Status |
|---|---|---|
| Virtual machine | **UTM** on macOS, VM named `Linux` | ✅ |
| Operating system | **Ubuntu 26.04.1 LTS** (ARM64 / aarch64), kernel 7.0 | ✅ |
| Desktop | `ubuntu-desktop-minimal` (graphical login) | ✅ |
| ROS 2 | **Lyrical Luth** (`ros-lyrical-desktop`, includes RViz) + `ros-dev-tools` | ✅ |
| Gazebo | **Gazebo Jetty** (`ros-lyrical-ros-gz`), software rendering | ✅ |
| Remote access | SSH from Mac Terminal (and VS Code Remote-SSH) | ✅ |

### VM details

| Setting | Value |
|---|---|
| Hostname | `marwa-server` |
| Username | `marmaria` |
| IP address | `192.168.64.2` |
| Disk | 60 GB (`/` expanded to full disk) |
| Memory | 8 GB (8192 MiB) |
| CPU cores | 4 |
| Display card | `virtio-gpu-gl-pci (GPU Supported)` |

---

## 2. What I did, step by step

### Part A: Install Ubuntu Server (11 Oct)
1. Installation type: **Ubuntu Server** (not minimized), no third-party drivers.
2. Network: kept defaults (DHCP gave `192.168.64.2`).
3. Proxy: left blank.
4. Mirror: the UAE mirror failed, so I switched to `http://archive.ubuntu.com/ubuntu/`.
5. Storage: **Use an entire disk** + LVM, no encryption.
6. Profile: server name `marwa-server`, user `marmaria`.
7. SSH: **Installed OpenSSH server**.
8. Featured snaps: none.
9. Rebooted, logged in, and installed updates:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
10. Expanded the disk from 30 GB to 60 GB:
    ```bash
    sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    df -h /
    ```

### Part B: Health checks (15 Oct)

| Check | Command | Result |
|---|---|---|
| Clock | `date` | Fixed (was 4 days behind) ✅ |
| Internet | `ping -c 3 google.com` | 0% packet loss ✅ |
| Package manager | `sudo apt update` | No errors ✅ |
| SSH service | `systemctl status ssh.socket` | active (listening) ✅ |
| SSH from Mac | `ssh marmaria@192.168.64.2` | Connected ✅ |

### Part C: Install ROS 2 Lyrical (15 Oct)
```bash
# 1. Prepare
sudo apt install -y locales software-properties-common curl
sudo add-apt-repository -y universe

# 2. Add the ROS 2 package source
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb

# 3. Install
sudo apt update && sudo apt install -y ros-dev-tools
sudo apt install -y ros-lyrical-ros-base ros-lyrical-demo-nodes-cpp ros-lyrical-demo-nodes-py

# 4. Load ROS in every terminal
echo "source /opt/ros/lyrical/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

**Test passed:** talker (C++) and listener (Python) communicated over `/chatter`.
```bash
ros2 run demo_nodes_cpp talker     # tab 1
ros2 run demo_nodes_py listener    # tab 2 -> "I heard: [Hello World: N]"
```

### Part D: Add desktop + Gazebo (20 Oct)
1. Shut down the VM, then in UTM settings set **8 GB RAM**, **4 cores**, and the **GPU Supported** display card.
2. Installed:
   ```bash
   sudo apt install -y ubuntu-desktop-minimal
   sudo apt install -y ros-lyrical-desktop ros-lyrical-ros-gz
   sudo reboot
   ```
3. The first Gazebo run crashed (Ogre renderer issue in the VM). Fixed with software rendering:
   ```bash
   LIBGL_ALWAYS_SOFTWARE=1 gz sim shapes.sdf
   echo "export LIBGL_ALWAYS_SOFTWARE=1" >> ~/.bashrc   # make it permanent
   ```
   **Test passed:** the shapes world loaded with a box, sphere, cylinder, cone, and capsule.

---

## 3. Problems I hit and how I fixed them

| Problem | Cause | Fix |
|---|---|---|
| UAE mirror failed during install | That server didn't respond | Used `http://archive.ubuntu.com/ubuntu/` |
| `lvextend` printed a help page | Two commands typed on one line | Run each command separately |
| `command not found: timedatect1` | Typed the number `1` instead of the letter `l` | Correct spelling is `timedatectl` / `systemctl` |
| Wrong date in the VM | VM was **suspended**, not shut down | `sudo chronyc makestep` |
| `systemd-timesyncd not found` | Ubuntu 26.04 uses **chrony** | `sudo systemctl restart chrony` |
| SSH "Connection refused" | SSH not active yet | `sudo systemctl enable --now ssh` |
| `apt: command not found` | Ran Linux commands in the **Mac** Terminal | Check the prompt: `%` = Mac, `$` = Ubuntu |
| UTM settings greyed out | VM was suspended | Start it, then `sudo shutdown now` |
| Gazebo crash (Ogre / segmentation fault) | VM graphics limits | `LIBGL_ALWAYS_SOFTWARE=1` |

---

## 4. Cheat sheet

### Which terminal am I in?
- `marwarashwan@marwas-MacBook-Pro-2 ~ %` → **Mac**
- `marmaria@marwa-server:~$` → **Ubuntu**

### Everyday commands

| Command | What it does |
|---|---|
| `ssh marmaria@192.168.64.2` | Connect to the VM from the Mac |
| `sudo shutdown now` | Turn off the VM properly (**always use this**) |
| `sudo reboot` | Restart the VM |
| `sudo apt update && sudo apt upgrade -y` | Install updates |
| `date` / `sudo chronyc makestep` | Check / fix the clock |
| `df -h /` | Disk space |
| `ip a` | Show the IP address |
| `Control + C` | Stop the running command |

### ROS 2 commands

| Command | What it does |
|---|---|
| `ros2 run <package> <node>` | Start a node |
| `ros2 node list` | List running nodes |
| `ros2 topic list` | List active topics |
| `ros2 topic echo /topic` | Watch messages on a topic |
| `ros2 topic info /topic` | Count publishers and subscribers |
| `printenv ROS_DISTRO` | Check the ROS version (should say `lyrical`) |

### Gazebo
| Command | What it does |
|---|---|
| `gz sim shapes.sdf` | Test world with basic shapes |
| `gz sim diff_drive.sdf` | Two small wheeled robots |

Run Gazebo from the **Ubuntu desktop terminal** (inside the VM window), not over SSH.

### Start-up routine
1. UTM → **▶** start the VM.
2. Log in (desktop) or `ssh marmaria@192.168.64.2` (Mac).
3. If the date is wrong: `sudo chronyc makestep`.

---

## 5. Next step: `rover_test` (my first ROS 2 package)

### What it is
A practice project that makes Gazebo's **blue two-wheeled robot drive in a square** while printing its position.

| Part | Job |
|---|---|
| **Gazebo** | Simulates the robot (`diff_drive.sdf`) |
| **Bridge** (`ros_gz_bridge`) | Passes messages between ROS 2 and Gazebo |
| **`square_driver` node** (Python) | Sends speed commands at 10 Hz and reads the position |

Topics used:
- `/model/vehicle_blue/cmd_vel` (`geometry_msgs/Twist`): commands **to** the robot
- `/model/vehicle_blue/odometry` (`nav_msgs/Odometry`): position **from** the robot

### How it maps to the Smart EV Explorer

| In `rover_test` | On the real car |
|---|---|
| Node sends speed commands | Node sends commands to the Arduino Mega, which drives the motors |
| Node reads the robot's position | Node reads the WT901 IMU and RPLIDAR S3 |
| Gazebo robot moves | Real car moves |

### How to run it
1. Copy the script to the VM (from the **Mac Terminal**, VM running):
   ```bash
   scp ~/Downloads/setup_rover_test.sh marmaria@192.168.64.2:~
   ssh marmaria@192.168.64.2
   bash setup_rover_test.sh
   ```
   **Pass:** ends with `DONE. Workspace: ~/ros2_ws`.
2. Run the test from the **Ubuntu desktop terminal**:
   ```bash
   ~/run_rover_test.sh
   ```
   **Pass:** the blue robot drives in a square and the terminal prints `Position x=... y=...`. Press **Ctrl + C** to stop.

> The square won't be perfect, because turns are timed. Using odometry for accurate turns is a good next exercise.

### What the script creates
```
~/ros2_ws/
└── src/rover_test/
    ├── package.xml
    ├── setup.py
    ├── setup.cfg
    ├── resource/rover_test
    └── rover_test/
        ├── __init__.py
        └── square_driver.py      <- the node
~/run_rover_test.sh               <- one-click launcher
```

### Full test file: `setup_rover_test.sh`

```bash
#!/bin/bash
# =============================================================
#  setup_rover_test.sh
#  Creates a ROS 2 workspace (~/ros2_ws) with a first package
#  "rover_test" containing a node that drives Gazebo's
#  vehicle_blue robot in a square and prints its position.
#
#  Run once:   bash setup_rover_test.sh
#  Then test:  ~/run_rover_test.sh   (from the Ubuntu DESKTOP terminal)
# =============================================================
set -e

echo ">>> Loading ROS 2 Lyrical..."
source /opt/ros/lyrical/setup.bash

WS=~/ros2_ws
PKG=$WS/src/rover_test

echo ">>> Creating workspace at $WS ..."
mkdir -p "$PKG/rover_test" "$PKG/resource"

# ---------- package.xml ----------
cat > "$PKG/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>rover_test</name>
  <version>0.1.0</version>
  <description>First ROS 2 test package: drives a Gazebo robot in a square.</description>
  <maintainer email="marmaria@example.com">marmaria</maintainer>
  <license>Apache-2.0</license>

  <exec_depend>rclpy</exec_depend>
  <exec_depend>geometry_msgs</exec_depend>
  <exec_depend>nav_msgs</exec_depend>
  <exec_depend>ros_gz_bridge</exec_depend>

  <export>
    <build_type>ament_python</build_type>
  </export>
</package>
EOF

# ---------- setup.py ----------
cat > "$PKG/setup.py" <<'EOF'
from setuptools import find_packages, setup

package_name = 'rover_test'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='marmaria',
    maintainer_email='marmaria@example.com',
    description='First ROS 2 test package: drives a Gazebo robot in a square.',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'square_driver = rover_test.square_driver:main',
        ],
    },
)
EOF

# ---------- setup.cfg ----------
cat > "$PKG/setup.cfg" <<'EOF'
[develop]
script_dir=$base/lib/rover_test
[install]
install_scripts=$base/lib/rover_test
EOF

# ---------- marker + python package ----------
touch "$PKG/resource/rover_test"
touch "$PKG/rover_test/__init__.py"

# ---------- the node ----------
cat > "$PKG/rover_test/square_driver.py" <<'EOF'
"""
square_driver: drives Gazebo's vehicle_blue in a square.

Publishes:  geometry_msgs/Twist     -> /model/vehicle_blue/cmd_vel
Subscribes: nav_msgs/Odometry       <- /model/vehicle_blue/odometry

Pattern: drive straight for `side_time` seconds, turn ~90 degrees, repeat.
Turns are timed, so the square won't be perfect (especially if the
simulation runs slower than real time) - fixing that with odometry
is a good next exercise.
"""
import math

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry


class SquareDriver(Node):
    def __init__(self):
        super().__init__('square_driver')

        # Parameters (can be changed from the command line)
        self.declare_parameter('cmd_topic', '/model/vehicle_blue/cmd_vel')
        self.declare_parameter('odom_topic', '/model/vehicle_blue/odometry')
        self.declare_parameter('speed', 0.5)        # m/s forward
        self.declare_parameter('turn_speed', 0.5)   # rad/s while turning
        self.declare_parameter('side_time', 4.0)    # seconds per side

        cmd_topic = self.get_parameter('cmd_topic').value
        odom_topic = self.get_parameter('odom_topic').value
        self.speed = float(self.get_parameter('speed').value)
        self.turn_speed = float(self.get_parameter('turn_speed').value)
        self.side_time = float(self.get_parameter('side_time').value)
        self.turn_time = (math.pi / 2.0) / self.turn_speed  # time for ~90 deg

        self.pub = self.create_publisher(Twist, cmd_topic, 10)
        self.create_subscription(Odometry, odom_topic, self.on_odom, 10)

        self.state = 'forward'
        self.sides_done = 0
        self.state_start = self.get_clock().now()
        self.timer = self.create_timer(0.1, self.step)  # 10 Hz control loop

        self.get_logger().info(
            f'Driving in a square: {self.speed} m/s, {self.side_time}s per side. '
            f'Publishing to {cmd_topic}'
        )

    def elapsed(self):
        return (self.get_clock().now() - self.state_start).nanoseconds / 1e9

    def switch(self, new_state):
        self.state = new_state
        self.state_start = self.get_clock().now()

    def step(self):
        msg = Twist()
        if self.state == 'forward':
            msg.linear.x = self.speed
            if self.elapsed() >= self.side_time:
                self.get_logger().info('Corner -> turning')
                self.switch('turn')
        else:  # turning
            msg.angular.z = self.turn_speed
            if self.elapsed() >= self.turn_time:
                self.sides_done += 1
                self.get_logger().info(f'Side {self.sides_done} done -> straight')
                self.switch('forward')
        self.pub.publish(msg)

    def on_odom(self, msg):
        p = msg.pose.pose.position
        self.get_logger().info(
            f'Position  x={p.x:6.2f} m   y={p.y:6.2f} m',
            throttle_duration_sec=1.0,
        )

    def stop(self):
        try:
            self.pub.publish(Twist())  # all zeros = stop
        except Exception:
            pass


def main():
    rclpy.init()
    node = SquareDriver()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.stop()
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == '__main__':
    main()
EOF

# ---------- build ----------
echo ">>> Building the workspace with colcon..."
cd "$WS"
colcon build --symlink-install

# ---------- auto-load in new terminals ----------
grep -qxF 'source ~/ros2_ws/install/setup.bash' ~/.bashrc || \
  echo 'source ~/ros2_ws/install/setup.bash' >> ~/.bashrc
grep -qxF 'export LIBGL_ALWAYS_SOFTWARE=1' ~/.bashrc || \
  echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> ~/.bashrc

# ---------- one-click run script ----------
cat > ~/run_rover_test.sh <<'EOF'
#!/bin/bash
# Starts Gazebo (diff_drive world), the ROS<->Gazebo bridge, and the
# square_driver node. Press Ctrl+C to stop everything.
source /opt/ros/lyrical/setup.bash
source ~/ros2_ws/install/setup.bash
export LIBGL_ALWAYS_SOFTWARE=1

cleanup() {
  echo ">>> Stopping bridge and Gazebo..."
  kill "$BRIDGE_PID" 2>/dev/null
  pkill -f "gz sim" 2>/dev/null
}
trap cleanup EXIT

echo ">>> 1/3 Starting Gazebo (window opens in ~30-60 s)..."
gz sim -r diff_drive.sdf &
sleep 15

echo ">>> 2/3 Starting ROS <-> Gazebo bridge..."
ros2 run ros_gz_bridge parameter_bridge \
  /model/vehicle_blue/cmd_vel@geometry_msgs/msg/Twist]gz.msgs.Twist \
  /model/vehicle_blue/odometry@nav_msgs/msg/Odometry[gz.msgs.Odometry &
BRIDGE_PID=$!
sleep 3

echo ">>> 3/3 Starting square_driver node (Ctrl+C to stop)..."
ros2 run rover_test square_driver
EOF
chmod +x ~/run_rover_test.sh

echo ""
echo "=========================================="
echo " DONE. Workspace: ~/ros2_ws"
echo " To run the test, open the Ubuntu DESKTOP"
echo " terminal and type:   ~/run_rover_test.sh"
echo "=========================================="
```

---

## 6. Roadmap for the Smart EV Explorer

1. ✅ Linux VM, ROS 2, Gazebo
2. ⬜ Run `rover_test`
3. ⬜ Model the car in Gazebo (size, wheels, LiDAR, IMU, ultrasonic)
4. ⬜ Obstacle-avoidance node using simulated LiDAR
5. ⬜ Check which ROS 2 version the **Jetson** runs (Humble/Jazzy vs Lyrical)
6. ⬜ Move nodes to the Jetson; connect the real sensors and the Arduino

**Notes:**
- Gazebo uses software rendering here, so keep simulation worlds simple.
- Simulation tests logic; motor behavior, sensor noise, and wiring still need real-hardware testing.
