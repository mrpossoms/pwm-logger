# PWM Logger / Generator
![logger](https://protean-io.herokuapp.com/imgs/logger.png)

## Overview

The Protean PWM logger was designed to facilitate the development of hobbyiest autonomous vehicle systems whose performance strongly depends on data collection and reproduction. The logger has the following functions.

* PWM signal generation for up to 6 channels.
* PMW signal decoding for up to 6 channels.
* Data access over I2C.

The PWM logger is built around Parallax's Propeller (P8X32A-Q44), an 8 core MCU which operates at ~20 MIPS per core. Dedicating each core's processing power to each servo channel offloads a potentially significant burden from your project's main computer. And allows for accurate decoding and generation of PWM signals.

## Usage

The PWM logger uses the I2C protocol for configuration and operation. It joins the bus as a slave device with the default 7-bit address of 0x69. The logger is capable and tested with clock speeds of 100KHz and 400KHz, but should be capable of higher frequencies.

## Firmware

The PWM logger's firmware is written in PASM.

### Building

