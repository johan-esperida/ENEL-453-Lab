`timescale 1ns / 1ps
//==============================================================================
// Package: disk_pkg
//
// Purpose
//   One place for every constant that more than one file needs. A module that
//   uses these constants starts with "import disk_pkg::*;". To change a value
//   (for example the encoder resolution), change it here, once, and every file
//   that uses it follows.
//
//   Two kinds of constant live here:
//     - project values: clock frequency, sample rate, encoder resolution ...
//     - data widths:    how many bits each kind of number needs
//
//   A constant used by only one file is declared in that file instead.
//
// Timing values and testbenches
//   The timing values (CLK_FREQ_HZ, CONTROL_FREQ_HZ, PWM_FREQ_HZ,
//   DEBOUNCE_TIME_MS) are used as the DEFAULT values of module parameters.
//   The closed-loop testbench overrides those parameters with a slower clock,
//   so that seconds of disk motion simulate in seconds, not hours.
//==============================================================================

package disk_pkg;

    //--------------------------------------------------------------------------
    // Clock and timing
    //--------------------------------------------------------------------------
    localparam int CLK_FREQ_HZ      = 100_000_000;  // Basys3 oscillator: 100 MHz
    localparam int CONTROL_FREQ_HZ  = 100;          // controller samples per second
                                                    // (same as ENEL 441 and ENCM 511)
    localparam int PWM_FREQ_HZ      = 10_000;       // motor PWM frequency, approximate
    localparam int DEBOUNCE_TIME_MS = 50;           // push-button must be steady this long

    //--------------------------------------------------------------------------
    // Encoder and setpoint
    //--------------------------------------------------------------------------
    localparam int ENCODER_LINES   = 512;                  // slots per revolution
    localparam int COUNTS_PER_REV  = 4 * ENCODER_LINES;    // x4 decoding: 2048
    localparam int SETPOINT_STEP   = COUNTS_PER_REV / 4;   // one button press: 90 deg = 512
    localparam int DEGREES_PER_REV = 360;

    //--------------------------------------------------------------------------
    // Data widths (number of bits)
    //--------------------------------------------------------------------------
    // Position and setpoint, signed: -32,768 to +32,767 counts = +/-16 revolutions.
    localparam int POSITION_WIDTH = 16;

    // Proportional gain Kp, unsigned: 0 to 15, from four slide switches.
    localparam int KP_WIDTH = 4;

    // PWM duty cycle, unsigned: 0 (off) to 255 (full power).
    localparam int DUTY_WIDTH = 8;

    // Motor command, signed: -255 to +255. One more bit than the duty for the sign.
    localparam int COMMAND_WIDTH = DUTY_WIDTH + 1;

    // Largest command (and largest duty cycle): 2^8 - 1 = 255 = full power.
    localparam int COMMAND_MAX = 2**DUTY_WIDTH - 1;

    // Angle shown on the display, unsigned: 0 to 359 degrees needs 9 bits.
    localparam int DEGREES_WIDTH = 9;

endpackage
