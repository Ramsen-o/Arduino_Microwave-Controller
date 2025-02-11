# Microwave Simulator - ATmega328P (Assembly)

## Overview
This project is an **assembly-language-based microwave simulator** for the **ATmega328P microcontroller**, 
typically used with an **Arduino Uno**. The program simulates a functional microwave by incorporating a joystick
for setting the cook time, an LED screen for display, a heater light, a cancel button, a door switch, a beeper,
and a **servo motor for rotating the plate** using **Pulse-Width Modulation (PWM)**.

## Hardware Components

- **ATmega328P Microcontroller** (e.g., Arduino Uno)
- **Joystick Module** (to set cook time)
- **LED Screen** (to display time and cooking status)
- **Heater Light (LED)** (simulating microwave operation)
- **Cancel Button** (to stop cooking)
- **Door Switch** (to detect door status)
- **Servo Motor** (to simulate rotating plate)

## Pin Configuration (Example)

| Component          | ATmega328P Pin                     |
| ------------------ | ---------------------------------- |
| Joystick X-Axis    | **A0 (ADC0)**                      |
| LED Display        | **Digital Pins (SPI/I2C)**         |
| Heater Light (LED) | **D9 (PWM)**                       |
| Cancel Button      | **D2 (INT0 - External Interrupt)** |
| Door Switch        | **D3 (INT1 - External Interrupt)** |
| Servo Motor        | **D6 (PWM Output)**                |

## Software Implementation

### 1. **Joystick-Based Cook Time Adjustment**

- Pressing the **joystick button** starts/pauses the cook time.
- The **joystick X-axis** is read via an **ADC (Analog-to-Digital Converter)**.
- Each **right movement** adds **10 seconds** to the cook time.
- Each **left movement** removes **10 seconds** from the cook time.
- Time is updated on the LED screen.

### 2. **Cooking Mode**

- The cook time countdown starts.
- The **heater light (LED) turns on**.
- The **servo motor is activated** using **PWM** to simulate the rotating plate.
- The remaining time is continuously displayed.

### 3. **Cancel Button Functionality**

- Pressing the **cancel button** stops cooking immediately.
- The **LED screen switches** to display the current **time of day**.
- **Cancel button** beeps when pressed

### 4. **Door Switch Simulation**

- If the **door is opened during cooking**, the microwave pauses.
- If the **door is closed again**, cooking resumes.

### 5. **Servo Motor (Rotating Plate) Control using PWM**

- A **PWM signal** is generated on **Pin D6** to control the **servo motor**.
- The motor turns at a controlled speed **only while cooking**.

## Assembly Code Overview

- The program is written in **AVR Assembly**.
- Uses **Interrupts** for the **Cancel Button** and **Door Switch**.
- Implements **PWM control** for the **servo motor**.
- Uses **ADC** for joystick input.

## How to Upload and Run the Code

1. **Assemble the circuit** as per the pin configuration.
2. **Write and assemble the AVR assembly code** using **Atmel Studio** or an assembler like **AVR-GCC**.
3. **Flash the program** onto the **ATmega328P** using an **AVR ISP programmer**.
4. **Power on the circuit** and test the microwave simulation.

## Future Improvements

- Add a **buzzer sound** when cooking starts/stops.
- Implement a **temperature sensor** for real-world applications.
- Use a **real-time clock (RTC) module** to keep track of the time of day.

**Author:** [Ramsen Oraha]
**Version:** 1.12
**Date:** [2025-02-11]

