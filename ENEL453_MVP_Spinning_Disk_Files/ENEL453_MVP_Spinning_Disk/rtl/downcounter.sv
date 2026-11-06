`timescale 1ns / 1ps
//==============================================================================
// Module: downcounter
//
// Purpose
//   Produces a one-clock-cycle pulse, "zero", once every PERIOD clock cycles.
//   This is the same module as in Lab 6.
//
//   The pulse is used as a CLOCK ENABLE, not as a clock. Everything in the
//   design still runs on the single 100 MHz clock; a block that should act
//   less often (for example the controller, 100 times per second) simply does
//   nothing on the clock edges where the enable pulse is 0. This keeps the
//   whole design in one clock domain, so no timing problems can arise between
//   clocks.
//
// Block diagram
//
//              +---------------------------------+
//   enable --->|  count: PERIOD-1, ..., 1, 0,    |
//              |         PERIOD-1, ..., 1, 0, ...|---> zero (1 for one cycle
//   clk ------>|  (counts down when enabled)     |           at each wrap)
//              +---------------------------------+
//
// Timing (PERIOD = 4, enable = 1)
//
//   clk     __/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__
//   count        3     2     1     0     3     2     1     0     3
//   zero    __________________________/-----\_________________/-----\_____
//
//   zero is registered, so it goes high on the clock edge after count = 0,
//   the same edge on which count wraps back to PERIOD-1 = 3.
//
// Equation
//   pulse frequency = CLK_FREQ / PERIOD
//   Example: 100,000,000 Hz / 1,000,000 = 100 Hz (the controller sample rate)
//
// Parameters
//   PERIOD : clock cycles between pulses. Must be 2 or more.
//
// Inputs
//   clk    : 100 MHz system clock
//   reset  : synchronous, active-high reset. Restarts the count at PERIOD-1.
//   enable : 1 = count down, 0 = hold the count (no pulses)
//
// Outputs
//   zero   : one-clock-cycle pulse every PERIOD cycles
//
// Internal signals
//   count : the down-counter, PERIOD-1 down to 0
//==============================================================================

module downcounter #(
    parameter int PERIOD = 1000
) (
    input  logic clk,
    input  logic reset,
    input  logic enable,
    output logic zero
);

    // Number of bits needed to hold the largest count value, PERIOD - 1, and
    // that starting value at exactly that width.
    localparam int                     COUNT_WIDTH = $clog2(PERIOD);
    localparam logic [COUNT_WIDTH-1:0] START_COUNT = COUNT_WIDTH'(PERIOD - 1);

    logic [COUNT_WIDTH-1:0] count;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= START_COUNT;
            zero  <= 1'b0;
        end else if (enable) begin
            if (count == 0) begin
                count <= START_COUNT;     // wrap around and start again
                zero  <= 1'b1;            // one pulse per period
            end else begin
                count <= count - 1'b1;
                zero  <= 1'b0;
            end
        end else begin
            zero <= 1'b0;                 // disabled: hold the count, no pulse
        end
    end

endmodule
