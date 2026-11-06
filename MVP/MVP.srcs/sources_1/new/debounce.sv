`timescale 1ns / 1ps
//==============================================================================
// Module: debounce
//
// Purpose
//   Cleans up a mechanical push-button. When a button is pressed or released,
//   its metal contacts bounce for a few milliseconds, so the signal flickers
//   between 0 and 1 many times before it settles. Without debouncing, one
//   press could look like several presses.
//
//   The idea is the same as the Lab 3 debouncer: the output only changes after
//   the input has stayed at the same level, without a single flicker, for
//   STABLE_TIME_MS milliseconds. This version takes its first two flip-flops
//   from the shared synchronizer module, so the bouncing input is synchronized
//   before anything else looks at it.
//
// Block diagram
//
//              +--------------+  button_sync            +------------------+
//   button --->| synchronizer |----------+------------->|                  |
//              |  (2 flip-    |          |              |  stability timer |
//              |   flops)     |          |   +-------+  |  (count)         |---> result
//              +--------------+          +-->| D   Q |->|  "changed?"      |
//                                            | prev  |  |                  |
//                                            +-------+  +------------------+
//
//   Every clock cycle the timer compares the synchronized button with its
//   value one cycle earlier (button_previous):
//     - they differ  -> the button is still bouncing: restart the count at 0
//     - they match   -> count up by one, until the count reaches MAX_COUNT
//     - at MAX_COUNT -> the button has been steady long enough: copy it to
//                       the output
//
// Timing (one press; the count only finishes once the bouncing stops)
//
//   button    __/-\_/-\/----------------------------\/-\_/-\___________________
//   count     0  0 0 00 1 2 3 ...   MAX              0 0 0 1 2 3 ...   MAX
//   result    ______________________/-------------------------------------\____
//                                   ^ steady for STABLE_TIME_MS            ^
//
// Equation
//   MAX_COUNT = clock cycles in the stable time
//             = (CLK_FREQ / 1000) * STABLE_TIME_MS
//   Example: (100,000,000 / 1000) * 50 ms = 100,000 * 50 = 5,000,000 cycles.
//   Dividing by 1000 first keeps the intermediate value small: computing
//   100,000,000 * 50 first would overflow a 32-bit integer.
//
// Parameters (defaults come from disk_pkg)
//   CLK_FREQ       : system clock frequency in Hz (default CLK_FREQ_HZ = 100 MHz)
//   STABLE_TIME_MS : how long, in ms, the button must stay steady
//                    (default DEBOUNCE_TIME_MS = 50 ms)
//
// Inputs
//   clk    : 100 MHz system clock
//   reset  : synchronous, active-high reset. Clears the count and the output.
//   button : raw push-button signal (asynchronous and bouncing)
//
// Outputs
//   result : debounced button level, 1 while the button is held down
//
// Internal signals
//   button_sync     : button after the two-flip-flop synchronizer (instance
//                     BUTTON_SYNCHRONIZER)
//   button_previous : button_sync delayed by one clock cycle
//   changed         : 1 when button_sync differs from button_previous, i.e.
//                     the button changed level in the last clock cycle
//   count           : stability timer, counts clock cycles without a change
//==============================================================================

module debounce
    import disk_pkg::*;                             // CLK_FREQ_HZ, DEBOUNCE_TIME_MS
#(
    parameter int CLK_FREQ       = CLK_FREQ_HZ,       // default 100 MHz
    parameter int STABLE_TIME_MS = DEBOUNCE_TIME_MS   // default 50 ms
) (
    input  logic clk,
    input  logic reset,
    input  logic button,
    output logic result
);

    localparam int MS_PER_SECOND = 1000;
    localparam int MAX_COUNT   = (CLK_FREQ / MS_PER_SECOND) * STABLE_TIME_MS;
    localparam int COUNT_WIDTH = $clog2(MAX_COUNT + 1);  // enough bits to hold MAX_COUNT
    localparam logic [COUNT_WIDTH-1:0] COUNT_LIMIT = COUNT_WIDTH'(MAX_COUNT);  // MAX_COUNT at that width

    logic                   button_sync;
    logic                   button_previous;
    logic                   changed;
    logic [COUNT_WIDTH-1:0] count;

    // Two-flip-flop synchronizer: the raw button can change at any time.
    synchronizer #(
        .WIDTH(1)
    ) BUTTON_SYNCHRONIZER (
        .clk(clk),          // system clock
        .d(button),         // raw, bouncing push-button
        .q(button_sync)     // synchronized button
    );

    // Remember the button level from the previous clock cycle. No reset is
    // needed: this flip-flop is reloaded on every clock edge.
    always_ff @(posedge clk) begin
        button_previous <= button_sync;
    end

    assign changed = (button_sync != button_previous);

    // Stability timer and output register.
    always_ff @(posedge clk) begin
        if (reset) begin
            count  <= '0;
            result <= 1'b0;
        end else if (changed) begin
            count  <= '0;                  // still bouncing: start timing again
        end else if (count < COUNT_LIMIT) begin
            count  <= count + 1'b1;        // steady so far: keep timing
        end else begin
            result <= button_sync;         // steady for the whole stable time
        end
    end

endmodule
