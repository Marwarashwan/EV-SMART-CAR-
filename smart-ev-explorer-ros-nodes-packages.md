---
component: ROS 2 nodes & packages plan
status: design reference — maps the v2 architecture onto a concrete ROS 2 workspace
---

# Smart EV Explorer — ROS 2 Nodes & Packages

This maps your v2 architecture (Jetson + Raspberry Pi 4, camera, LiDAR, IMU, GPS, motor driver, e-stop/relay, dashboard, storage) onto an actual ROS 2 workspace: which packages to create, which nodes go in each, and which *existing* community packages can replace writing something from scratch.

## Workspace layout (your original structure, filled in)

```
your_ws/
└── src/
    ├── motor_control_pkg/
    │   ├── motor_driver_node
    │   └── estop_monitor_node
    ├── perception_pkg/
    │   ├── camera_node
    │   └── lidar_node
    ├── localization_pkg/
    │   ├── imu_node
    │   ├── gps_node
    │   └── ekf_node            ← sensor fusion (new addition, see below)
    └── dashboard_pkg/
        ├── telemetry_publisher_node
        └── data_logger_node     ← data storage, grouped here
```

## Package-by-package breakdown

### 1. `motor_control_pkg` — runs on the Raspberry Pi 4

| Node | Role | Topics/Interfaces |
|---|---|---|
| `motor_driver_node` | Converts velocity commands into PWM/direction signals for the motor driver | Subscribes `/cmd_vel` (`geometry_msgs/Twist`) → writes GPIO/PWM |
| `estop_monitor_node` | Watches the e-stop/relay line and publishes system status | Publishes `/estop_status` (`std_msgs/Bool`), can also trigger an immediate `/cmd_vel` zero-out |

**Possible existing packages instead of hand-rolling everything:**
- `ros2_control` + `diffdrive_arduino`-style hardware interface — if you want standard ROS 2 control conventions instead of a custom node reading `/cmd_vel` directly. Heavier to set up, but gives you a conventional controller/interface split.
- `twist_mux` — if you'll ever have more than one source of velocity commands (e.g. joystick + autonomous nav + a safety override), this arbitrates between them cleanly instead of custom logic.
- `diagnostic_updater`/`diagnostic_msgs` — standard way to publish the e-stop/motor-driver health status so it's visible to `rqt_robot_monitor` or your dashboard.

### 2. `perception_pkg` — runs on the Jetson Orin

| Node | Role | Topics/Interfaces |
|---|---|---|
| `camera_node` | Captures and publishes camera frames | Publishes `/camera/image_raw` (`sensor_msgs/Image`) |
| `lidar_node` | Reads the RPLIDAR S3 and publishes scan data | Publishes `/scan` (`sensor_msgs/LaserScan`) |

**Possible existing packages (strongly recommended here — don't write these from scratch):**
- **`rplidar_ros`** — official/community driver for RPLIDAR S2/S3; publishes `/scan` directly. This alone replaces your `lidar_node`.
- **`usb_cam`** or **`v4l2_camera`** — standard USB camera driver nodes, publish `/image_raw` + camera info. If it's a CSI camera on the Jetson specifically, NVIDIA's **`isaac_ros_argus_camera`** (from Isaac ROS) is built for that.
- **`image_transport`** — compressed image transport so camera frames don't flood your Ethernet link between Jetson and Pi/dashboard.
- **`slam_toolbox`** or **`rtabmap_ros`** — once you want mapping/localization from the LiDAR+camera combo, rather than just raw scan/image topics.
- **`nav2`** (Navigation2) — the standard stack for path planning/obstacle avoidance once perception is in place; it consumes `/scan` and odometry and outputs `/cmd_vel`, which lines up directly with your `motor_driver_node`.

### 3. `localization_pkg` — runs on the Raspberry Pi 4

| Node | Role | Topics/Interfaces |
|---|---|---|
| `imu_node` | Reads the WT901 IMU over serial, publishes orientation/accel/gyro | Publishes `/imu/data` (`sensor_msgs/Imu`) |
| `gps_node` | Reads GPS over serial, publishes fix data | Publishes `/gps/fix` (`sensor_msgs/NavSatFix`) |
| `ekf_node` *(new — worth adding)* | Fuses IMU + GPS (+ wheel odometry if available) into a single pose estimate | Subscribes `/imu/data`, `/gps/fix` → publishes `/odometry/filtered` |

**Possible existing packages:**
- **`witmotion_ros`** or writing your own thin wrapper around the `witmotion`/`pywitmotion` Python library (from your IMU doc) — a custom `imu_node` is reasonable here since WitMotion's protocol isn't universally wrapped.
- **`nmea_navsat_driver`** — standard ROS 2 package for NMEA-output GPS modules; publishes `/gps/fix` and `/gps/vel` directly, likely replaces your `gps_node` entirely if your GPS module outputs standard NMEA sentences.
- **`robot_localization`** — this is the standard package for `ekf_node`/`ukf_node`. It's a drop-in EKF/UKF that fuses IMU + GPS + odometry with just a YAML config, no custom fusion math needed. Strongly recommended over writing your own filter.

### 4. `dashboard_pkg` — runs on the Jetson (or wherever the dashboard connects)

| Node | Role | Topics/Interfaces |
|---|---|---|
| `telemetry_publisher_node` | Aggregates key system state for the dashboard | Publishes a custom `/telemetry` message (speed, battery, estop status, GPS fix, etc.) |
| `data_logger_node` | Records runs for later analysis | Subscribes to relevant topics, writes to disk/DB |

**Possible existing packages:**
- **`rosbridge_suite`** — exposes ROS 2 topics over a WebSocket, so a web-based dashboard (HTML/JS) can subscribe to `/telemetry`, `/scan`, `/gps/fix`, etc. directly without a custom publisher protocol. This is probably the single most useful package for your dashboard.
- **`ros2bag`** (built into ROS 2, not a separate install) — records *all* topics to a `.bag` file with one command; this can **replace `data_logger_node` entirely** for raw logging, unless you need custom structured storage (e.g., writing straight to a database for a web dashboard to query).
- **`foxglove_bridge`** — alternative to `rosbridge_suite`, pairs with the free Foxglove Studio app for a ready-made live dashboard/visualizer with zero custom frontend work — worth considering if you don't want to build a dashboard UI from scratch.

## Project-wide / cross-cutting packages

These aren't tied to one package above — they support the whole system:

| Package | Why you'd want it |
|---|---|
| `robot_state_publisher` + `tf2` | Standard way to track coordinate frames (IMU frame → base frame → camera frame → LiDAR frame) so nav2/rtabmap/robot_localization all agree on geometry. Needed once you have more than one sensor frame. |
| `urdf` (just an XML description, no install) | Describes your robot's physical frames/joints for `robot_state_publisher` and visualization in RViz. |
| `rviz2` | Visualize `/scan`, `/image_raw`, `/odometry/filtered`, TF frames — your main debugging tool during integration. |
| `joint_state_publisher` | Only relevant if you add articulated parts (steering, arms) later. |
| `teleop_twist_keyboard` | Quick way to manually drive the robot via `/cmd_vel` before autonomy is wired up — useful for testing `motor_driver_node` in isolation. |
| `micro_ros` | Only relevant if you later add a microcontroller (e.g., an Arduino handling low-level motor PWM) that needs to speak ROS 2 natively instead of over a custom serial protocol. |

## Suggested order to actually build this

1. **Bring up `motor_control_pkg` first**, tested with `teleop_twist_keyboard` — this validates your Pi↔motor driver wiring and the e-stop/relay logic in isolation, with no sensors involved yet.
2. **Bring up `perception_pkg`** using `rplidar_ros` and `usb_cam`/`v4l2_camera` — these are near-zero custom code, just config.
3. **Bring up `localization_pkg`** with your custom `imu_node`, `nmea_navsat_driver` for GPS, and `robot_localization`'s EKF node — this is where most of your actual custom code lives (the IMU wrapper).
4. **Wire TF frames + `robot_state_publisher`** once more than one sensor is running, so everything agrees on geometry in RViz.
5. **Add `dashboard_pkg`** last, using `rosbridge_suite` (or `foxglove_bridge`) once there's real data worth displaying.
6. **Layer in `nav2`** only once you want autonomous navigation rather than just sensing + manual driving.

## Notes

- Everything above assumes ROS 2 (not ROS 1) — matches your Jetson/JetPack + Ubuntu plan.
- Several "possible packages" above are drop-in replacements for nodes you'd otherwise write by hand (`rplidar_ros`, `nmea_navsat_driver`, `robot_localization`, `ros2bag`) — worth checking these before writing custom code, since your actual original work is really just the IMU driver, the motor driver interface, and the dashboard/telemetry layer.
- Message types referenced above (`sensor_msgs/Imu`, `sensor_msgs/NavSatFix`, `sensor_msgs/LaserScan`, `geometry_msgs/Twist`) are all standard ROS 2 interfaces — no custom `.msg` files needed except for `/telemetry` in the dashboard.

## Sources
- Package names and roles reflect standard, actively maintained ROS 2 ecosystem packages (rplidar_ros, nmea_navsat_driver, robot_localization, nav2, rosbridge_suite, foxglove_bridge, ros2_control) as of general ROS 2 ecosystem knowledge — verify exact package availability for your specific ROS 2 distribution (e.g. Humble/Jazzy) before adding to `package.xml`.
