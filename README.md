# PWM Logger / Generator
![logger](https://protean-io.herokuapp.com/imgs/logger.png)

## Overview

The Protean PWM logger was designed to facilitate the development of hobbyist autonomous vehicle systems whose performance strongly depends on servo data collection and reproduction. The logger has the following default functions, but is fully reprogrammable.

* PWM signal generation for up to 6 channels.
* PMW signal decoding for up to 6 channels.
* Data access over I2C.

The PWM logger is built around Parallax's Propeller (P8X32A-Q44), an 8 core MCU which operates at ~20 MIPS per core. Dedicating each core's processing power to each servo channel offloads a potentially significant burden from your project's main computer. And allows for accurate decoding and generation of PWM signals.

## Usage

The PWM logger uses the I2C protocol for configuration and operation. It joins the bus as a slave device with the default 7-bit **address 0x69**. The logger is capable of, and tested with clock speeds of 100KHz and 400KHz but should be capable of higher speeds.

### Register usage

When configuring or using the PWM logger the first thing that your application will have to do is begin with an I2C write addressing the device and writing one byte which will select that register specifically. If you are planning on writing to the selected register you should continue with the current write transaction. Otherwise, end the transaction and follow up with a read.

### Device Registers

* 0x00 - Configuration register: Controls the mode of operation of the PWM logger. By default, the value in that register can have the following values.
   * 0 -> Echo off, this means the PWM logger will ignore PWM signals on the input channels. Instead it will generate the pulse width in the channel register.
   * 1 -> Echo on, this means the PWM logger will measure PWM signals on the input channels, and store the measurement in each channel register.
* 0x0N - Channel register: These registers store the pulse width as a pseudo time from [0, 255]. The pulse duration in seconds for a given channel register value can be obtained with the following operation (_value_ << 10) / _clock speed_ where the clock speed in the normal case is 8 * 10^7 Hz.
  * Once a channel register has been selected with a write, you can continue reading or writing multiple bytes as the selected register will be auto incremented. This allows you to collect data from, or write new timings to, all the servo channels in a single I2C transaction.
  * When the device is in echo mode the measured pulse widths are stored in each respective channel register.
  * When the device has echo mode disabled, the last pulse width in each channel register will be generated on that corresponding channel. That means writing to that register will cause the device to generate that particular pulse width.

## Firmware

The PWM logger's firmware is written in PASM, the propeller's native language. More information about PASM can be found in the [propeller manual](https://www.parallax.com/sites/default/files/downloads/P8X32A-Web-PropellerManual-v1.2.pdf).

### Building

To build the firmware you will need to have Parallax's [SimpleIDE](http://learn.parallax.com/tutorials/language/propeller-c/propeller-c-set-simpleide) installed.

