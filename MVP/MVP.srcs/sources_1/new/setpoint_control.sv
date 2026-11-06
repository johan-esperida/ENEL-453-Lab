`timescale 1ns / 1ps
//==============================================================================
// Module: setpoint_control
//
// Purpose
//   Holds the setpoint: the position, in encoder counts, that the controller
//   tries to move the disk to. Each press of the "up" button adds SETPOINT_STEP
//   counts; each press of the "down" button subtracts SETPOINT_STEP counts.
//   With SETPOINT_STEP = 512 and 2048 counts per revolution, each press moves
//   the setpoint 90 degrees.
//
// Edge detection
//   The debounced buttons stay at 1 for as long as they are held down, which
//   is millions of clock cycles. The setpoint must change once per PRESS, not
//   once per clock cycle, so the module looks for the rising edge: the one
//   clock cycle where the button is 1 now but was 0 in the previous cycle.
//
//     clk           __/--\__/--\__/--\__/--\__/--\__/--\__
//     step_up       ________/-----------------------------    (held down)
//     up_previous   ______________/-----------------------    (one cycle later)
//     up_pressed    ________/-----\_______________________    = step_up AND NOT up_previous
//     setpoint       0            | 512                       changes exactly once
//
// Block diagram (the step_down path is identical to the step_up path)
//
//                 +-------+
//   step_up --+-->| D   Q |--> up_previous --[NOT]--+
//             |   +-------+                         |
//             +-------------------------------->[AND]--> up_pressed ---+
//                                                                      |
//                                                                      v
//                                                    +-----------------------------+
//                       down_pressed --------------->| setpoint register           |
//                                                    |   up_pressed:   + STEP_SIZE |---> setpoint
//                                                    |   down_pressed: - STEP_SIZE |
//                                                    |   otherwise:    hold        |
//                                                    +-----------------------------+
//
// Constants (from disk_pkg)
//   SETPOINT_STEP  : setpoint change per button press, in encoder counts (512)
//   POSITION_WIDTH : width of the setpoint (16 bits, signed)
//
// Inputs
//   clk       : 100 MHz system clock
//   reset     : synchronous, active-high reset. Sets the setpoint to 0.
//   step_up   : debounced "up" button level (1 while held)
//   step_down : debounced "down" button level (1 while held)
//
// Outputs
//   setpoint  : desired disk position in encoder counts, signed 16 bits
//
// Internal signals
//   up_previous, down_previous : the button levels one clock cycle earlier
//   up_pressed, down_pressed   : one-clock-cycle pulses, one per button press
//   STEP_SIZE (constant)       : SETPOINT_STEP as a 16-bit signed number
//==============================================================================

module setpoint_control
    import disk_pkg::*;               // POSITION_WIDTH, SETPOINT_STEP
(
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             step_up,
    input  logic                             step_down,
    output logic signed [POSITION_WIDTH-1:0] setpoint
);

    // SETPOINT_STEP (512) as a number of the same width and type as setpoint.
    localparam logic signed [POSITION_WIDTH-1:0] STEP_SIZE = POSITION_WIDTH'(SETPOINT_STEP);

    logic up_previous;
    logic down_previous;
    logic up_pressed;
    logic down_pressed;

    // Remember the button levels from the previous clock cycle. No reset is
    // needed: these registers just follow the buttons, and debounce holds the
    // buttons at 0 during reset anyway.
    always_ff @(posedge clk) begin
        up_previous   <= step_up;
        down_previous <= step_down;
    end

    // Rising edge = pressed now, but not pressed one cycle ago.
    assign up_pressed   = step_up   && !up_previous;
    assign down_pressed = step_down && !down_previous;

    // Step the setpoint once per press. If both buttons are pressed in the same
    // clock cycle, "up" wins.
    always_ff @(posedge clk) begin
        if (reset)
            setpoint <= '0;
        else if (up_pressed)
            setpoint <= setpoint + STEP_SIZE;
        else if (down_pressed)
            setpoint <= setpoint - STEP_SIZE;
    end

endmodule
