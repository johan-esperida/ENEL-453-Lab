`timescale 1ns / 1ps
//==============================================================================
// Module: pwm
//
// Purpose
//   Pulse-width modulation: a square wave whose fraction of "on" time (the
//   duty cycle) is set by the number duty_cycle. Driving a motor with PWM
//   varies its average voltage, and so its torque, from 0% to 100%.
//
//   This is the Lab 6 pwm module with two changes:
//     1. count_enable: the counter only advances on count_enable pulses, so
//        the PWM frequency can be set slower than the 100 MHz clock. The
//        L298N motor driver cannot switch faster than a few tens of kHz.
//     2. pwm_out is registered, so it is glitch-free when it leaves the FPGA.
//
// How it works
//   A counter runs 0, 1, 2, ..., 254, 0, 1, ... (255 steps per period). The
//   output is on while counter < duty_cycle:
//
//   duty_cycle = 64 (64/255 = 25%):
//
//   counter  0 ... 63 | 64 ...                          254 | 0 ... 63 | 64 ...
//   pwm_out  ---------\_____________________________________/---------\________
//            |<------------------- one period (255 steps) ------------>|
//
//   duty_cycle =   0 -> counter < 0   is never true -> always off  (0%)
//   duty_cycle = 255 -> counter < 255 is always true -> always on  (100%)
//
// Equations (WIDTH = 8)
//   duty cycle    = duty_cycle / 255
//   PWM frequency = (count_enable pulse rate) / 255
//   Example: count_enable at 2.564 MHz (100 MHz / 39) -> 2.564 MHz / 255
//            = 10.06 kHz PWM
//
// Parameters
//   WIDTH : number of bits in duty_cycle and the counter
//           (default DUTY_WIDTH = 8, from disk_pkg)
//
// Inputs
//   clk          : 100 MHz system clock
//   reset        : synchronous, active-high reset. Clears the counter and output.
//   enable       : 1 = run; 0 = output held off and counter held at 0
//   count_enable : one-clock-cycle pulses that advance the counter by one step
//   duty_cycle   : on-time, 0 (always off) to 2**WIDTH - 1 (always on)
//
// Outputs
//   pwm_out      : the PWM waveform
//
// Internal signals
//   counter : position within the PWM period, 0 to MAX_CODE - 1
//==============================================================================

module pwm
    import disk_pkg::*;                 // DUTY_WIDTH
#(
    parameter int WIDTH = DUTY_WIDTH    // default 8 bits
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    input  logic             count_enable,
    input  logic [WIDTH-1:0] duty_cycle,
    output logic             pwm_out
);

    // Largest duty_cycle value: all ones (255 for WIDTH = 8). The counter
    // stops one short of it, at 254, so duty_cycle = 255 means 100% on.
    localparam logic [WIDTH-1:0] MAX_CODE = '1;

    logic [WIDTH-1:0] counter;

    always_ff @(posedge clk) begin
        if (reset || !enable) begin
            counter <= '0;
        end else if (count_enable) begin
            if (counter == MAX_CODE - 1'b1)
                counter <= '0;                 // end of period: start again
            else
                counter <= counter + 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset)
            pwm_out <= 1'b0;
        else
            pwm_out <= enable && (counter < duty_cycle);
    end

endmodule
