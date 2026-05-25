# PDM-PCM_audio_decimator

**Difficulty:** Intermediate

**Uses MCU:** Yes

**External Hardware:**  PDM MEMS Microphone Breakout Board

## Overview

This project implements a lightweight **PDM-to-PCM audio conversion pipeline** using a **3-stage CIC (Cascaded Integrator Comb) filter** on FPGA fabric. The goal is to convert high-speed 1-bit PDM microphone data into usable 16-bit PCM audio while operating under strict FPGA resource limitations.
Because traditional FIR/MAC-based filters are too resource-intensive, the system uses a CIC filter architecture built entirely from:
- Adders
- Subtractors
- Delay registers

This allows real-time audio decimation with very low FPGA utilization.
- **1-bit 2 MHz PDM**
→ into → **16-bit PCM at 32 kHz**

## Hardware Architecture

### FPGA Fabric
- Generates the 2 MHz audio clock
- Directly interfaces with the PDM microphone
- Executes the CIC filter
- Outputs decimated PCM audio

The entire processing chain uses less than 40% of the FPGA fabric.

### RP2040 Microcontroller
- Runs at 133 MHz
- Receives PCM samples from the FPGA
- Applies DSP filters and gain control
- Streams processed audio to an external DAC/speaker

The FPGA asserts an interrupt whenever a new PCM sample is available.

## Project Phases

### Stage 1
- Pure RTL behavioral simulation
- Synthetic PDM bitstream generation
- CIC verification inside Verilog testbench

### Stage 2
- Interface the FPGA with the MCU using the SPI protocol
- Using sample audio, verify the interface
- Audio streamed into MATLAB for analysis

### Stage 3
- Add external PDM MEMS Microphone Breakout Board
- Real-time standalone audio decimation
- Digital stethoscope style implementation

## Current Status

- [x] CIC RTL implementation completed
- [x] Behavioral simulation operational
- [x] Startup synchronization issue resolved
- [x] Decimation and PCM extraction verified
- [ ] Interface FPGA and MCU using SPI protocol
- [ ] Verify the interface by driving sample audio through the MCU

---

