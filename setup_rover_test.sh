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
