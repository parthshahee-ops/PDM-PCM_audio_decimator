# RTL Simulation

## Overview

This folder contains RTL simulation files, testbenches, and waveform dumps used to verify the PDM-to-PCM conversion pipeline.

The simulation validates the behaviour of the implemented CIC (Cascaded Integrator-Comb) filter and ensures stable PCM sample generation without clock edge violations or
timing inconsistencies.

Xilinx Vivado is used for waveform analysis and RTL verification.

---

## Simulation Methodology

A manually generated PDM bitstream is used as the input source for simulation. The bit patterns are designed to mimic waveform-like behaviour and test the response of the CIC filter under continuous streaming conditions.

Example PDM stream segments:

```verilog
pdm_stream[0:7]    = 8'b10101010;
pdm_stream[8:15]   = 8'b11111101;
pdm_stream[16:23]  = 8'b11001000;
pdm_stream[24:31]  = 8'b00001000;
```
The generated PCM output is monitored alongside the PDM input waveform to verify:

* CIC filter operation
* PCM sample generation
* Timing behaviour
* Signal stability

---

## Waveform Output

![RTL Simulation Waveform](https://github.com/parthshahee-ops/PDM-PCM_audio_decimator/blob/main/Simulation/waveform.png)

The waveform above shows:

* Clock signal behaviour
* PDM input stream
* Generated PCM[15:0]

---

## Folder Contents

```text
RTL_Simulation/
│
├── Source File
├── Testbench
├── Waveform Screenshot
└── .wcfg waveform configuration file
```

---

## Simulation Outputs

Waveforms are analyzed using:

* Vivado Waveform Viewer

The simulation outputs help validate:

* PCM generation accuracy
* CIC filter behaviour
* Clock synchronization
* Stable signal processing

---
