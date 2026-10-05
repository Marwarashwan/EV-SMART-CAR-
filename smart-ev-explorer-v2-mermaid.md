# Smart EV Explorer — System Diagram v2 (Mermaid)

Paste only the code between the triple backticks into your GitHub `README.md`. GitHub renders it automatically.

```mermaid
flowchart TB
    BATT["48V Battery"]
    FUSE["Fuse"]
    ESTOP["Emergency Stop"]
    ISOREG["Isolated Reg + Filter"]
    MDRIVER["Motor Driver"]
    MOTOR["Motor"]
    REG12["Reg 1: 48V to 12V"]
    REG5["Reg 2: 48V to 5V"]
    JETSON["Jetson Orin"]
    RPI["Raspberry Pi 4"]
    RELAY["Relay SW cutoff"]
    CAM["Camera"]
    LIDAR["RPLIDAR S3"]
    IMU["WT901 IMU"]
    GPS["GPS"]
    DASH["Dashboard"]
    STORE["Data Storage"]
    GND["Common GND Bus"]

    BATT --> FUSE
    FUSE --> ESTOP
    ESTOP --> ISOREG
    ESTOP --> REG12
    ESTOP --> REG5
    ISOREG --> MDRIVER
    MDRIVER --> MOTOR
    REG12 --> JETSON
    REG5 --> RPI
    REG5 --> RELAY
    RELAY --> MDRIVER
    RPI --> JETSON
    JETSON --> CAM
    JETSON --> LIDAR
    RPI --> IMU
    RPI --> GPS
    JETSON --> DASH
    JETSON --> STORE
    BATT -.-> GND
    MDRIVER -.-> GND
    JETSON -.-> GND
    RPI -.-> GND

    classDef power fill:#D85A30,stroke:#4A1B0C,color:#FAECE7
    classDef motor fill:#993C1D,stroke:#4A1B0C,color:#FAECE7
    classDef rail12 fill:#BA7517,stroke:#412402,color:#FAEEDA
    classDef rail5 fill:#0F6E56,stroke:#04342C,color:#E1F5EE
    classDef compute fill:#534AB7,stroke:#26215C,color:#EEEDFE
    classDef sensor fill:#993556,stroke:#4B1528,color:#FBEAF0
    classDef extras fill:#7F77DD,stroke:#26215C,color:#EEEDFE
    classDef ground fill:#5F5E5A,stroke:#2C2C2A,color:#F1EFE8

    class BATT,FUSE,ESTOP power
    class ISOREG,MDRIVER,MOTOR motor
    class REG12,JETSON rail12
    class REG5,RPI,RELAY rail5
    class CAM,LIDAR,IMU,GPS sensor
    class DASH,STORE extras
    class GND ground
```

### Legend
- Orange — power generation and safety cutoffs (battery, fuse, emergency stop)
- Dark red/coral — motor branch (isolated supply, driver, motor)
- Amber — 12V rail and Jetson
- Teal — 5V rail, Raspberry Pi 4, and the software relay cutoff
- Pink — sensors (camera, LiDAR, IMU, GPS)
- Light purple — dashboard and data storage
- Gray — common ground bus (dashed = ground returns)

### Notes
- This is the updated v2 architecture: Raspberry Pi 4 in place of the Arduino Mega, plus the motor driver, camera, GPS, dashboard, and storage.
- It's a logical block diagram, not a true schematic — good for a README or portfolio page, not a substitute for your KiCad or hand-drawn circuit schematic.
- Recolor any group by editing its `classDef` hex values at the bottom.
