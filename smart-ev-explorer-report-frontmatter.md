---
title: Smart EV Explorer — Project Report (Front Matter)
status: draft — abstract, introduction, problem statement, objectives, scope
---

# Smart EV Explorer

## Abstract

The Smart EV Explorer is an educational autonomous electric vehicle platform developed to demonstrate how low-cost sensing, embedded computing, and the Robot Operating System (ROS 2) can be combined to give a small electric buggy basic self-navigation and safety capabilities. The project builds on an earlier, simpler vehicle control unit — a Raspberry Pi–based system handling keyless access, ultrasonic parking assistance, a touchscreen dashboard, and vehicle lighting — and extends it into a two-computer architecture: an NVIDIA Jetson Orin Nano for perception (stereo depth camera, LiDAR-based mapping) and a Raspberry Pi 4 for lower-level sensing and safety-critical control (IMU, GPS, emergency stop, battery monitoring). The two computers communicate over Ethernet using ROS 2's built-in networking, publishing sensor data as standardized ROS 2 topics that are fused using coordinate-frame transforms (TF2) referenced to the vehicle's physical center (`base_link`). This report documents the system's design evolution — from the original mechanical/electrical kit, through the current ROS 2–based sensing and control architecture, to two proposed low-cost additions (battery state-of-charge monitoring and environmental sensing) — along with the mechanical structure, communication design, and operational procedures that support it.

## Introduction

Electric buggies and small autonomous ground vehicles are widely used as educational platforms because they combine mechanical, electrical, and software engineering in a single, tangible system. The Smart EV Explorer project was undertaken to build such a platform from the ground up: starting from a base vehicle control unit handling essential vehicle functions, and progressively adding the sensing, computation, and software architecture needed for the vehicle to perceive its environment and operate with a degree of autonomy.

The project reflects a layered engineering approach. At the mechanical level, a tubular chassis with a roll cage, 3D-printed mounting brackets, and laser-cut acrylic body panels form the vehicle's physical structure. At the electrical level, a 48V battery system is distributed through fused, isolated paths to the motor, the control electronics, and the onboard computers. At the software level, the system runs on ROS 2 — a widely used robotics middleware — distributed across two computers chosen for their complementary strengths: a GPU-capable Jetson module for vision and mapping, and a Raspberry Pi for simpler, fast, safety-relevant sensing.

This report consolidates the technical work completed to date: the base vehicle control system, the migration to a ROS 2–based two-computer sensing architecture, the physical and software integration of the five core sensors (camera, LiDAR, IMU, GPS, ultrasonic), the coordinate-frame design that allows their readings to be combined accurately, and two proposed sensor additions that extend the system's safety and environmental awareness at low cost and low integration risk.

## Problem Statement

A vehicle intended to navigate or assist a driver autonomously must be able to answer three questions continuously and in real time: *where am I, what is around me, and is it safe to keep moving?* Answering these requires multiple sensors of different types, each reporting data in its own physical reference frame and at its own update rate, processed by computing hardware suited to each task's demands. The core engineering problem addressed by this project is integrating that heterogeneous sensor and compute hardware — camera, LiDAR, IMU, GPS, ultrasonic, two distinct onboard computers — into a single, consistent system where every sensor's reading can be trusted to refer to the same physical vehicle and combined safely and correctly, while preserving simple, fail-safe operation (a hardware emergency stop that works independently of the software).

## Objectives

1. Establish a reliable communication link between the two onboard computers (Jetson Orin Nano and Raspberry Pi 4) suitable for real-time sensor data exchange.
2. Install and configure ROS 2 (Jazzy) on the Jetson, including CUDA/TensorRT dependencies and the ZED SDK, to support camera-based perception.
3. Define the vehicle's physical coordinate frame structure (`base_link` and sensor frames) so that all sensor data can be transformed into a single, consistent reference frame.
4. Integrate the five core sensors — stereo camera, LiDAR, IMU, GPS, and ultrasonic — as ROS 2 nodes publishing standard message types.
5. Identify and specify low-cost, low-integration-risk additions (battery monitoring, environmental sensing) that extend the system's safety and situational awareness without disrupting existing architecture.
6. Produce documentation — technical and user-facing — sufficient for both continued development and operation by someone without an engineering background.

## Scope

This report covers the project from its base hardware configuration through to the currently proposed sensor extensions:

- **In scope:**
  - The base Vehicle Control Unit: mechanical structure (chassis, 3D-printed mounts, acrylic covers), electrical system (48V distribution, relays, NFC access, ultrasonic parking sensors, LED lighting, touchscreen dashboard), as originally implemented on the Raspberry Pi.
  - The current Smart EV Explorer compute and sensing architecture: Jetson Orin Nano + Raspberry Pi 4 running ROS 2, connected over Ethernet, with ROS_DOMAIN_ID–based node discovery.
  - The five core sensors (camera, LiDAR, IMU, GPS, ultrasonic), their ROS 2 package integration, and their coordinate-frame (TF2/URDF) representation relative to `base_link`.
  - Two proposed additional sensors: battery state-of-charge monitoring (INA219/INA226) and environmental sensing (BME280), including their proposed wiring, ROS 2 node design, and package placement.
  - Supporting documentation: setup guides (Linux/ROS 2 installation), the physical build (mechanical section), and the end-user operating manual.

- **Out of scope:**
  - Full autonomous navigation and path planning (SLAM/Nav2 configuration beyond the sensing layer that feeds it).
  - Any sensor or feature beyond the five core sensors and the two proposed additions (e.g., the base kit's NFC/relay/LED subsystems are documented as inherited mechanical/electrical context, not re-engineered as part of the ROS 2 sensing architecture).
  - Performance validation, field testing results, or formal safety certification — this report documents design and integration work completed to date, not a final validated product.

## Document Map

| Topic | Where it's covered |
|---|---|
| Jetson↔Pi communication, Linux/ROS 2 installation | `jetson-pi-link-and-mac-setup.md` |
| ROS 2 packages/nodes structure | `smart-ev-explorer-ros-nodes-packages.md` |
| Coordinate frames, `base_link`, starter URDF | `smart-ev-explorer-tf-coordinate-frames.md` |
| Battery + environmental sensor additions | `smart-ev-explorer-battery-env-sensor.md` |
| Mechanical build (chassis, 3D-printed parts, acrylic covers) | Section 5 of `smart-ev-explorer-user-manual.md` |
| End-user operation | `smart-ev-explorer-user-manual.md` |
