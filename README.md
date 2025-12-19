# 5-DOF Robotic Manipulator
This repository includes the necessary code to run both the Processing based GUI and the Arduino IDE microcontroller robot control algorithm

![Status](https://img.shields.io/badge/Status-Prototype-orange)
![Platform](https://img.shields.io/badge/Platform-Arduino%20%7C%20Processing-blue)

## 📖 Project Overview
This repository contains the firmware and control software for a custom-built 5-Degree-of-Freedom (DoF) robotic arm. The robot operates using a hybrid actuation system:
* **Joints 1-3:** DC Motors with custom Closed-Loop PD Control (using potentiometers).
* **Joints 4-5:** Servomotors for wrist orientation and gripper actuation.

The system is capable of teleoperation via a Processing-based GUI, allowing for manual joint control and coordinate-based (XYZ) movement commands.

## 🛠️ Hardware Requirements

**Electronics:**
* **Microcontroller:** Elegoo UNO R3 (or compatible Arduino)
* **Motor Drivers:** L298N Dual H-Bridge
* **Power Supply:** GL NPS 100-12 (12V Output)
* **Actuators (Main Axes):** JGA25-370 12V DC Motors (15 RPM output)
* **Actuators (End Effector):** Standard Servos (x2)
* **Sensors:** Linear Potentiometers

**Wiring Pinout:**
* **Motor 1 (Base):** EN: 9, IN1: 8, IN2: 7, POT: A0
* **Motor 2 (Shoulder):** EN: 10, IN1: 11, IN2: 12, POT: A1
* **Motor 3 (Elbow):** EN: 6, IN1: 5, IN2: 4, POT: A2
* **Wrist Servo:** Pin 3
* **Gripper Servo:** Pin 2

## 💻 Software Dependencies

1.  **Arduino IDE**
    * Standard `Servo.h` library.
2.  **Processing IDE**
    * `ControlP5` library (Install via Sketch > Import Library > Add Library).
    * `processing.serial` library.

## 🚀 Installation & Usage

1.  **Arduino:**
    * Open the Arduino code below.
    * Connect your board via USB.
    * Upload the sketch.
2.  **Processing:**
    * Open the Processing code below.
    * Ensure the `ControlP5` library is installed.
    * **Important:** Check the line `String portName = Serial.list()[7];` in `setup()`. You may need to change the index `[7]` to match your computer's USB port index.
    * Run the sketch.
3.  **Operation:**
    * Use **Manual Mode** to move sliders and calibrate positions.
    * Use **XYZ Mode** to send coordinate commands, nothing will happen since it is not yet fully implemented
