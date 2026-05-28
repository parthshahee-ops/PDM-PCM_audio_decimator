# 16-Bit PDM to PCM Audio Pipeline
## Overview

* This module implements a real-time PDM-to-16-bit PCM audio conversion pipeline on an FPGA.
* The generated PCM samples are transferred to the RP2040 MCU using SPI communication and visualized in MATLAB for real-time waveform analysis and debugging.
---

## Folder Structure
```text
PDM_PCM_16bit/
│
├── pdm_to_pcm_16bit.v
├── rp2040_spi_audio_receiver.py
├── matlab_waveform_visualizer.m
└── README.md
```
---

## Components
### `pdm_to_pcm_16bit.v`
Main FPGA RTL module responsible for:
* Capturing 1-bit PDM microphone data
* Performing decimation and filtering
* Generating 16-bit PCM samples
* Streaming PCM output through SPI

---

### `rp2040_spi_audio_receiver.py`
MicroPython script running on the RP2040 MCU.
* Operates as SPI Master
* Reads serialized PCM data from FPGA
* Sends received PCM samples to the host PC through UART
---

### `matlab_waveform_visualizer.m`
* Live serial data reception
* Real-time PCM waveform plotting
* Continuous hardware debugging support
* MATLAB-based oscilloscope-style monitoring

---

## Communication Architecture

Due to the limited FPGA-to-MCU interconnect width available on the Shrike LITE board, direct parallel PCM transfer is not feasible.
The system therefore, uses SPI communication:
* RP2040 acts as SPI Master
* FPGA acts as SPI Slave
* FPGA serializes PCM samples
* RP2040 periodically reads PCM data

---
