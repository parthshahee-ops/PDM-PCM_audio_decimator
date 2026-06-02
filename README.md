# PDM-PCM Audio Decimator

**Difficulty:** Intermediate

**Uses MCU:** Yes (RP2040)

**External Hardware:** Vicharak Shrike Lite, PDM MEMS Microphone Breakout Board, Jumper Cables

## Overview
This project implements a lightweight **PDM-to-PCM audio conversion pipeline** using a **3-stage CIC (Cascaded Integrator Comb) filter** on FPGA fabric. The goal is to convert high-speed 1-bit PDM microphone data into usable 16-bit PCM audio while operating under strict FPGA resource limitations.
Because traditional FIR/MAC-based filters are too resource-intensive, the system uses a CIC filter architecture built entirely from:
- Adders
- Subtractors
- Delay registers

This allows real-time audio decimation with very low FPGA utilization.
- **1-bit 2 MHz PDM**
→ into → **16-bit PCM at 32 kHz**

## Compatibility

| Board                | Firmware                | Status     |
| -------------------- | ----------------------- | ---------- |
| Shrike Lite (RP2040) | `firmware/micropython/` | ✅ Tested   |
| Shrike (RP2350)      | N/A                     | ⬜ Untested |
| Shrike-fi (ESP32-S3) | N/A                     | ⬜ Untested |

## Hardware Setup

| Component | Purpose |
|-----------|----------|
| Shrike Lite | Main FPGA + MCU development platform |
| PDM MEMS Microphone Breakout Board | Captures PDM audio input signals |
| Jumper Cables | To connect Micropone with FPGA |

![System Architecture](./images/system_architecture.png)

The Shrike Lite board provides only six hardwired FPGA-to-MCU interconnect signals. Due to this limitation, PCM audio samples cannot be transferred using a wide parallel interface.
To overcome this constraint:
* FPGA operates as SPI Slave
* RP2040 operates as SPI Master
* FPGA serializes generated PCM samples
* RP2040 periodically reads PCM data over SPI

## Quick Start

### FPGA

1. Open `pcm_to_pdm.ffpga` in Go Configure Software Hub
2. Click Synthesize → Generate Bitstream
3. Output will be in `ffpga/build/`

### RP2040

1. Copy `rp2040_spi_audio_receiver.py` to the Thonny IDE
2. Execute the script
3. Verify serial output is being generated

### MATLAB

Run `realtime_pcm_plotter.m` to visualize incoming PCM samples in real time.

## Build From Source

### FPGA (Verilog)

Source files are located in: `ffpga/src/`

Available implementations:

| File                 | Description                      |
| -------------------- | -------------------------------- |
| `pdm_to_pcm_8bit.v`  | 8-bit PCM output implementation  |
| `pdm_to_pcm_16bit.v` | 16-bit PCM output implementation |
| `spi_interface.v`    | SPI communication interface      |
| `pcm_to_pdm`         | Final Implementation             |

### Simulation

Simulation files are located in: `ffpga/sim/`
The RTL simulation verifies:

* CIC filter functionality
* PCM sample generation
* SPI communication logic
* Timing correctness

### Simulation Output

PDM-PCM Simulation
![PDM-PCM Simulation](./images/rtl_waveform_sim.png)

## How It Works

### 1. PDM Audio Capture

The PDM microphone generates a high-frequency 1-bit PDM stream representing the audio waveform.

### 2. CIC Filtering and Decimation

The FPGA implements a CIC filter that:

* Integrates incoming PDM samples
* Performs decimation
* Generates lower-rate PCM samples

To verify output, two PCM implementations are provided:
* 8-bit PCM output
* 16-bit PCM output

### 3. SPI Transfer
Generated PCM samples are serialized and transferred from the FPGA to the RP2040 via SPI.
![SPI Interface Simulation](./images/spi_inferface.png)

### 4. MATLAB Visualization

The RP2040 forwards PCM samples to the host PC where MATLAB visualizes the waveform in real time.

## Expected Output

### 8-bit PCM Output

![8-bit PCM Output](./images/matlab_output_8bit.png)

### 16-bit PCM Output

![16-bit PCM Output](./images/matlab_output_16bit.png)

### Final Output

The generated waveform should resemble the original input pattern, with the 16-bit implementation providing higher amplitude resolution.
The final output resembles a sine waveform.

## References

* https://ieeexplore.ieee.org/document/10153161
* https://ieeexplore.ieee.org/document/11385174
---
