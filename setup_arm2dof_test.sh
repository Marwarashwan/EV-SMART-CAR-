#!/bin/bash
# =============================================================
#  setup_arm2dof_test.sh
#  Adds a ROS 2 package "arm2dof_test" to ~/ros2_ws with:
#    - a 2-DOF arm (2 revolute joints, horizontal plane) for Gazebo
#    - arm_draw : node that makes the arm's tip trace a circle (IK)
#    - arm_goto : node that moves the tip to one (x, y) point
#
#  Run once:   bash setup_arm2dof_test.sh
#  Then test:  ~/run_arm_test.sh              (circle)
#              ~/run_arm_test.sh goto 0.6 0.3 (move tip to x=0.6, y=0.3)
#  Run tests from the Ubuntu DESKTOP terminal (Gazebo needs the screen).
# =============================================================
set -e

echo ">>> Loading ROS 2 Lyrical..."
source /opt/ros/lyrical/setup.bash

WS=~/ros2_ws
PKG=$WS/src/arm2dof_test

echo ">>> Creating package at $PKG ..."
mkdir -p "$PKG/arm2dof_test" "$PKG/resource" "$PKG/worlds"

# ---------- package.xml ----------
cat > "$PKG/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>arm2dof_test</name>
  <version>0.1.0</version>
  <description>2-DOF arm in Gazebo controlled from ROS 2 with inverse kinematics.</description>
  <maintainer email="marmaria@example.com">marmaria</maintainer>
  <license>Apache-2.0</license>

  <exec_depend>rclpy</exec_depend>
  <exec_depend>std_msgs</exec_depend>
  <exec_depend>sensor_msgs</exec_depend>
  <exec_depend>ros_gz_bridge</exec_depend>

  <export>
    <build_type>ament_python</build_type>
  </export>
</package>
EOF

# ---------- setup.py ----------
cat > "$PKG/setup.py" <<'EOF'
from setuptools import find_packages, setup

package_name = 'arm2dof_test'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        ('share/' + package_name + '/worlds', ['worlds/arm2dof.sdf']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='marmaria',
    maintainer_email='marmaria@example.com',
    description='2-DOF arm in Gazebo controlled from ROS 2 with inverse kinematics.',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'arm_draw = arm2dof_test.arm_draw:main',
            'arm_goto = arm2dof_test.arm_goto:main',
        ],
    },
)
EOF

# ---------- setup.cfg ----------
cat > "$PKG/setup.cfg" <<'EOF'
[develop]
script_dir=$base/lib/arm2dof_test
[install]
install_scripts=$base/lib/arm2dof_test
EOF

touch "$PKG/resource/arm2dof_test"
touch "$PKG/arm2dof_test/__init__.py"

# ---------- Gazebo world with the 2-DOF arm ----------
cat > "$PKG/worlds/arm2dof.sdf" <<'EOF'
<?xml version="1.0"?>
<sdf version="1.9">
  <world name="arm2dof_world">

    <plugin filename="gz-sim-physics-system" name="gz::sim::systems::Physics"/>
    <plugin filename="gz-sim-user-commands-system" name="gz::sim::systems::UserCommands"/>
    <plugin filename="gz-sim-scene-broadcaster-system" name="gz::sim::systems::SceneBroadcaster"/>

    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.9 0.9 0.9 1</diffuse>
      <specular>0.2 0.2 0.2 1</specular>
      <direction>-0.5 0.1 -0.9</direction>
    </light>

    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry><plane><normal>0 0 1</normal><size>20 20</size></plane></geometry>
        </collision>
        <visual name="visual">
          <geometry><plane><normal>0 0 1</normal><size>20 20</size></plane></geometry>
          <material>
            <ambient>0.8 0.8 0.8 1</ambient>
            <diffuse>0.8 0.8 0.8 1</diffuse>
          </material>
        </visual>
      </link>
    </model>

    <!-- 2-DOF arm: both joints rotate about the vertical (z) axis,
         so the arm moves in a horizontal plane (like a SCARA arm).
         L1 = 0.5 m, L2 = 0.4 m. Shoulder (joint1) is at x=0, y=0. -->
    <model name="arm">
      <pose>0 0 0 0 0 0</pose>

      <link name="base">
        <pose>0 0 0 0 0 0</pose>
        <inertial>
          <pose>0 0 0.2 0 0 0</pose>
          <mass>5.0</mass>
          <inertia><ixx>0.075</ixx><iyy>0.075</iyy><izz>0.016</izz><ixy>0</ixy><ixz>0</ixz><iyz>0</iyz></inertia>
        </inertial>
        <visual name="base_visual">
          <pose>0 0 0.2 0 0 0</pose>
          <geometry><cylinder><radius>0.08</radius><length>0.4</length></cylinder></geometry>
          <material><ambient>0.3 0.3 0.3 1</ambient><diffuse>0.3 0.3 0.3 1</diffuse></material>
        </visual>
        <collision name="base_collision">
          <pose>0 0 0.2 0 0 0</pose>
          <geometry><cylinder><radius>0.08</radius><length>0.4</length></cylinder></geometry>
        </collision>
      </link>

      <joint name="fix_to_world" type="fixed">
        <parent>world</parent>
        <child>base</child>
      </joint>

      <link name="link1">
        <pose>0 0 0.42 0 0 0</pose>
        <inertial>
          <pose>0.25 0 0 0 0 0</pose>
          <mass>1.0</mass>
          <inertia><ixx>0.0005</ixx><iyy>0.021</iyy><izz>0.021</izz><ixy>0</ixy><ixz>0</ixz><iyz>0</iyz></inertia>
        </inertial>
        <visual name="link1_visual">
          <pose>0.25 0 0 0 0 0</pose>
          <geometry><box><size>0.5 0.06 0.04</size></box></geometry>
          <material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material>
        </visual>
        <visual name="joint1_visual">
          <geometry><cylinder><radius>0.05</radius><length>0.06</length></cylinder></geometry>
          <material><ambient>0.9 0.6 0.1 1</ambient><diffuse>0.9 0.6 0.1 1</diffuse></material>
        </visual>
      </link>

      <joint name="joint1" type="revolute">
        <parent>base</parent>
        <child>link1</child>
        <axis>
          <xyz>0 0 1</xyz>
          <limit><lower>-3.1</lower><upper>3.1</upper></limit>
          <dynamics><damping>0.5</damping></dynamics>
        </axis>
      </joint>

      <link name="link2">
        <pose>0.5 0 0.47 0 0 0</pose>
        <inertial>
          <pose>0.2 0 0 0 0 0</pose>
          <mass>0.8</mass>
          <inertia><ixx>0.0003</ixx><iyy>0.011</iyy><izz>0.011</izz><ixy>0</ixy><ixz>0</ixz><iyz>0</iyz></inertia>
        </inertial>
        <visual name="link2_visual">
          <pose>0.2 0 0 0 0 0</pose>
          <geometry><box><size>0.4 0.05 0.04</size></box></geometry>
          <material><ambient>0.1 0.7 0.3 1</ambient><diffuse>0.1 0.7 0.3 1</diffuse></material>
        </visual>
        <visual name="joint2_visual">
          <geometry><cylinder><radius>0.04</radius><length>0.06</length></cylinder></geometry>
          <material><ambient>0.9 0.6 0.1 1</ambient><diffuse>0.9 0.6 0.1 1</diffuse></material>
        </visual>
        <visual name="tip_visual">
          <pose>0.4 0 0 0 0 0</pose>
          <geometry><sphere><radius>0.035</radius></sphere></geometry>
          <material><ambient>0.9 0.1 0.1 1</ambient><diffuse>0.9 0.1 0.1 1</diffuse></material>
        </visual>
      </link>

      <joint name="joint2" type="revolute">
        <parent>link1</parent>
        <child>link2</child>
        <axis>
          <xyz>0 0 1</xyz>
          <limit><lower>-3.1</lower><upper>3.1</upper></limit>
          <dynamics><damping>0.3</damping></dynamics>
        </axis>
      </joint>

      <!-- Position controllers: send an angle (rad) to each joint -->
      <plugin filename="gz-sim-joint-position-controller-system"
              name="gz::sim::systems::JointPositionController">
        <joint_name>joint1</joint_name>
        <topic>/arm/joint1/cmd_pos</topic>
        <p_gain>40</p_gain>
        <i_gain>0.5</i_gain>
        <d_gain>4</d_gain>
        <i_max>2</i_max>
        <i_min>-2</i_min>
        <cmd_max>60</cmd_max>
        <cmd_min>-60</cmd_min>
      </plugin>

      <plugin filename="gz-sim-joint-position-controller-system"
              name="gz::sim::systems::JointPositionController">
        <joint_name>joint2</joint_name>
        <topic>/arm/joint2/cmd_pos</topic>
        <p_gain>25</p_gain>
        <i_gain>0.3</i_gain>
        <d_gain>2</d_gain>
        <i_max>2</i_max>
        <i_min>-2</i_min>
        <cmd_max>40</cmd_max>
        <cmd_min>-40</cmd_min>
      </plugin>

      <!-- Publishes the measured joint angles -->
      <plugin filename="gz-sim-joint-state-publisher-system"
              name="gz::sim::systems::JointStatePublisher">
        <topic>/arm/joint_states</topic>
      </plugin>
    </model>

  </world>
</sdf>
EOF

# ---------- shared kinematics ----------
cat > "$PKG/arm2dof_test/kinematics.py" <<'EOF'
"""Forward and inverse kinematics for a 2-link planar arm.

        tip (x, y)
          o
         /  L2
   joint2 o
         /  L1
  joint1 o  (origin)

theta1: angle of link 1 from the x-axis
theta2: angle of link 2 relative to link 1
"""
import math

L1 = 0.5  # m, must match the SDF model
L2 = 0.4  # m


def forward(theta1, theta2):
    """Joint angles (rad) -> tip position (m)."""
    x = L1 * math.cos(theta1) + L2 * math.cos(theta1 + theta2)
    y = L1 * math.sin(theta1) + L2 * math.sin(theta1 + theta2)
    return x, y


def inverse(x, y, elbow_up=True):
    """Tip position (m) -> joint angles (rad). Returns None if unreachable."""
    c2 = (x * x + y * y - L1 * L1 - L2 * L2) / (2.0 * L1 * L2)
    if c2 < -1.0 or c2 > 1.0:
        return None
    theta2 = math.acos(c2)
    if not elbow_up:
        theta2 = -theta2
    theta1 = math.atan2(y, x) - math.atan2(L2 * math.sin(theta2),
                                           L1 + L2 * math.cos(theta2))
    return theta1, theta2
EOF

# ---------- node: draw a circle ----------
cat > "$PKG/arm2dof_test/arm_draw.py" <<'EOF'
"""arm_draw: the arm's red tip traces a circle using inverse kinematics.

Publishes:  std_msgs/Float64        -> /arm/joint1/cmd_pos, /arm/joint2/cmd_pos
Subscribes: sensor_msgs/JointState  <- /arm/joint_states
"""
import math

import rclpy
from rclpy.node import Node
from std_msgs.msg import Float64
from sensor_msgs.msg import JointState

from arm2dof_test.kinematics import forward, inverse


class ArmDraw(Node):
    def __init__(self):
        super().__init__('arm_draw')
        self.declare_parameter('center_x', 0.55)
        self.declare_parameter('center_y', 0.0)
        self.declare_parameter('radius', 0.2)
        self.declare_parameter('period', 12.0)   # seconds per circle

        self.cx = float(self.get_parameter('center_x').value)
        self.cy = float(self.get_parameter('center_y').value)
        self.r = float(self.get_parameter('radius').value)
        self.period = float(self.get_parameter('period').value)

        self.pub1 = self.create_publisher(Float64, '/arm/joint1/cmd_pos', 10)
        self.pub2 = self.create_publisher(Float64, '/arm/joint2/cmd_pos', 10)
        self.create_subscription(JointState, '/arm/joint_states', self.on_joints, 10)

        self.target = (self.cx + self.r, self.cy)
        self.start = self.get_clock().now()
        self.create_timer(0.05, self.step)  # 20 Hz

        self.get_logger().info(
            f'Drawing a circle: center=({self.cx}, {self.cy}) m, '
            f'radius={self.r} m, {self.period}s per lap')

    def step(self):
        t = (self.get_clock().now() - self.start).nanoseconds / 1e9
        a = 2.0 * math.pi * t / self.period
        x = self.cx + self.r * math.cos(a)
        y = self.cy + self.r * math.sin(a)
        sol = inverse(x, y)
        if sol is None:
            self.get_logger().warn(f'Point ({x:.2f}, {y:.2f}) is out of reach',
                                   throttle_duration_sec=2.0)
            return
        self.target = (x, y)
        self.pub1.publish(Float64(data=sol[0]))
        self.pub2.publish(Float64(data=sol[1]))

    def on_joints(self, msg):
        angles = {}
        for name, pos in zip(msg.name, msg.position):
            if name.endswith('joint1'):
                angles['j1'] = pos
            elif name.endswith('joint2'):
                angles['j2'] = pos
        if 'j1' not in angles or 'j2' not in angles:
            return
        x, y = forward(angles['j1'], angles['j2'])
        err = math.hypot(x - self.target[0], y - self.target[1])
        self.get_logger().info(
            f'Joints: {math.degrees(angles["j1"]):7.1f} deg, '
            f'{math.degrees(angles["j2"]):7.1f} deg | '
            f'Tip: x={x:5.2f} y={y:5.2f} m | error={err * 100:4.1f} cm',
            throttle_duration_sec=1.0)


def main():
    rclpy.init()
    node = ArmDraw()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == '__main__':
    main()
EOF

# ---------- node: go to one point ----------
cat > "$PKG/arm2dof_test/arm_goto.py" <<'EOF'
"""arm_goto: move the arm's tip to one (x, y) point.

Usage:  ros2 run arm2dof_test arm_goto 0.6 0.3
Reach:  0.1 m to 0.9 m from the base.
"""
import math
import sys

import rclpy
from rclpy.node import Node
from std_msgs.msg import Float64

from arm2dof_test.kinematics import inverse


class ArmGoto(Node):
    def __init__(self, x, y):
        super().__init__('arm_goto')
        self.pub1 = self.create_publisher(Float64, '/arm/joint1/cmd_pos', 10)
        self.pub2 = self.create_publisher(Float64, '/arm/joint2/cmd_pos', 10)
        self.sol = inverse(x, y)
        self.count = 0
        if self.sol is None:
            self.get_logger().error(
                f'({x}, {y}) is out of reach. Distance from base must be 0.1-0.9 m.')
            return
        self.get_logger().info(
            f'Target ({x}, {y}) m -> joint1={math.degrees(self.sol[0]):.1f} deg, '
            f'joint2={math.degrees(self.sol[1]):.1f} deg')
        self.create_timer(0.1, self.send)

    def send(self):
        # Send a few times so the bridge surely delivers it
        self.pub1.publish(Float64(data=self.sol[0]))
        self.pub2.publish(Float64(data=self.sol[1]))
        self.count += 1


def main():
    args = rclpy.utilities.remove_ros_args(sys.argv)[1:]
    if len(args) != 2:
        print('Usage: ros2 run arm2dof_test arm_goto X Y   (meters, e.g. 0.6 0.3)')
        return
    x, y = float(args[0]), float(args[1])
    rclpy.init()
    node = ArmGoto(x, y)
    try:
        while rclpy.ok() and node.sol is not None and node.count < 20:
            rclpy.spin_once(node, timeout_sec=0.2)
        if node.sol is not None:
            node.get_logger().info('Command sent. The arm holds this position.')
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == '__main__':
    main()
EOF

# ---------- build ----------
echo ">>> Building the workspace with colcon..."
cd "$WS"
colcon build --symlink-install

grep -qxF 'source ~/ros2_ws/install/setup.bash' ~/.bashrc || \
  echo 'source ~/ros2_ws/install/setup.bash' >> ~/.bashrc
grep -qxF 'export LIBGL_ALWAYS_SOFTWARE=1' ~/.bashrc || \
  echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> ~/.bashrc

# ---------- one-click run script ----------
cat > ~/run_arm_test.sh <<'EOF'
#!/bin/bash
# Usage:
#   ~/run_arm_test.sh              -> tip draws a circle
#   ~/run_arm_test.sh goto X Y     -> tip moves to (X, Y) meters
source /opt/ros/lyrical/setup.bash
source ~/ros2_ws/install/setup.bash
export LIBGL_ALWAYS_SOFTWARE=1

WORLD="$(ros2 pkg prefix arm2dof_test)/share/arm2dof_test/worlds/arm2dof.sdf"

cleanup() {
  echo ">>> Stopping bridge and Gazebo..."
  kill "$BRIDGE_PID" 2>/dev/null
  pkill -f "gz sim" 2>/dev/null
}
trap cleanup EXIT

echo ">>> 1/3 Starting Gazebo with the 2-DOF arm (window opens in ~30-60 s)..."
gz sim -r "$WORLD" &
sleep 15

echo ">>> 2/3 Starting ROS <-> Gazebo bridge..."
ros2 run ros_gz_bridge parameter_bridge \
  /arm/joint1/cmd_pos@std_msgs/msg/Float64]gz.msgs.Double \
  /arm/joint2/cmd_pos@std_msgs/msg/Float64]gz.msgs.Double \
  /arm/joint_states@sensor_msgs/msg/JointState[gz.msgs.Model &
BRIDGE_PID=$!
sleep 3

if [ "$1" = "goto" ]; then
  echo ">>> 3/3 Moving tip to ($2, $3)... Press Ctrl+C to close everything."
  ros2 run arm2dof_test arm_goto "$2" "$3"
  wait "$BRIDGE_PID"
else
  echo ">>> 3/3 Drawing a circle (Ctrl+C to stop)..."
  ros2 run arm2dof_test arm_draw
fi
EOF
chmod +x ~/run_arm_test.sh

echo ""
echo "=========================================="
echo " DONE. Package: ~/ros2_ws/src/arm2dof_test"
echo " Run from the Ubuntu DESKTOP terminal:"
echo "   ~/run_arm_test.sh             (circle)"
echo "   ~/run_arm_test.sh goto 0.6 0.3"
echo "=========================================="
