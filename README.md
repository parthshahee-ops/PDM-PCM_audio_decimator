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

## System Architecture
![System Architecture](assets/System%20Architecture)

## Hardware Architecture
### Hardware Requirements
| Component | Purpose |
|-----------|----------|
| Shrike Lite | Main FPGA + MCU development platform |
| PDM MEMS Microphone Breakout Board | Captures PDM audio input signals |

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

## Folder Structure

```text id="4fh8t1"
PDM-PCM_audio_decimator/
│
├── Simulation/
│   ├── Source Files
│   ├── Testbenches
│   ├── Output Waveform 
│   └── .vcd files
│
├── SPI_Interface/
│   ├── SPI communication modules
│   ├── SPI loopback verification logic
│   └── RP2040 SPI receiver script
│
├── PDM_PCM_8bit/
│   ├── 8-bit PDM-to-PCM conversion pipeline
│   ├── RP2040 receiver script
│   └── MATLAB script
│
├── PDM_PCM_16bit/
│   ├── 16-bit PDM-to-PCM conversion pipeline
│   ├── RP2040 receiver script
│   └── MATLAB script
│
├── README.md
└── .gitignore
```



## Project Flow

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

## Development Flow

- CIC RTL implementation completed
- Behavioral simulation operational
- Startup synchronization issue resolved
- Decimation and PCM extraction verified
- Interface FPGA and MCU using SPI protocol
- Debug the PCM input using MATLAB
- Verify the interface by driving sample audio through the MCU

## References
- IEEE Xplore: [PDM Audio Signal Processing Using FPGA and MCU](https://ieeexplore.ieee.org/document/10153161)
- IEEE Xplore: [Real-Time FPGA-Based Audio Processing System](https://ieeexplore.ieee.org/document/11385174)
---

