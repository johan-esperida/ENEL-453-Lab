`timescale 1ns / 1ps
//==============================================================================
// Module: quad_decoder
//
// Purpose
//   Turns the two square-wave channels of a quadrature encoder, A and B, into
//   a signed position count.
//
//   The encoder has two light sensors looking at a slotted disk. They are
//   placed a quarter of a slot apart, so A and B are square waves 90 degrees
//   out of phase. Which one changes first tells the direction of rotation:
//
//   Turning forward (A leads B):          Turning backward (B leads A):
//
//     A   ____/---------\_________/-----     A   _________/---------\__________
//     B   _________/---------\__________     B   ____/---------\_________/-----
//     AB   00 | 10 | 11 | 01 | 00 | 10 |     AB   00 | 01 | 11 | 10 | 00 | 01 |
//         (each "|" is an edge of A or B: one count)
//
//   Every change of A or B is one count ("x4 decoding": four counts per slot).
//   The encoder on the bench has 512 slots (lines) per revolution, so one
//   revolution is 512 x 4 = 2048 counts, and one count = 360/2048, about
//   0.18 deg.
//
// State diagram
//   AB moves around this ring, one step per edge. Following the arrows is
//   forward (+1); going against the arrows is backward (-1).
//
//                    +1
//            00 ----------> 10
//             ^              |
//          +1 |              | +1
//             |              v
//            01 <---------- 11
//                    +1
//
//   A jump across the ring (00 <-> 11 or 10 <-> 01) means both channels
//   changed in the same clock cycle. That cannot happen with a real encoder
//   sampled at 100 MHz, so it is treated as noise and ignored.
//
// How it works
//   ab_previous holds A and B from the last clock cycle. Each cycle the pair
//   {ab_previous, ab} is looked up in a table of the eight legal one-step
//   moves: four forward moves add 1, four backward moves subtract 1, and
//   anything else (no change, or an illegal jump) leaves the count alone.
//
// Constants (from disk_pkg)
//   POSITION_WIDTH = 16 (signed position)
//
// Inputs
//   clk      : 100 MHz system clock
//   reset    : synchronous, active-high reset. Sets the position to 0.
//   a, b     : encoder channels A and B, ALREADY SYNCHRONIZED to clk
//
// Outputs
//   position : signed position in counts. 16 bits holds -32,768 to +32,767,
//              which is +/-16 revolutions: far more than position control needs.
//
// Internal signals
//   ab          : the two channels as a pair, {A, B}
//   ab_previous : the pair one clock cycle earlier
//==============================================================================

module quad_decoder
    import disk_pkg::*;               // POSITION_WIDTH
(
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             a,
    input  logic                             b,
    output logic signed [POSITION_WIDTH-1:0] position
);

    logic [1:0] ab;
    logic [1:0] ab_previous;

    assign ab = {a, b};

    // Remember A and B from the previous clock cycle. Reloaded every clock
    // edge, so no reset is needed.
    always_ff @(posedge clk) begin
        ab_previous <= ab;
    end

    // Count one step for each legal move around the ring.
    always_ff @(posedge clk) begin
        if (reset) begin
            position <= '0;
        end else begin
            case ({ab_previous, ab})
                //--------------------------------------------------------------
                // TODO: add the eight legal moves around the ring.
                //
                //   - The four FORWARD moves, 00 -> 10 -> 11 -> 01 -> 00,
                //     add 1 to position.
                //   - The four BACKWARD moves (the same ring, the other way
                //     round) subtract 1 from position.
                //
                //   Each case item is the 4-bit pair {ab_previous, ab}: for
                //   example, a jump from 00 to 11 would be written 4'b00_11
                //   (that one is illegal: it belongs in no list). Case items that do
                //   the same thing can share one line, separated by commas:
                //
                //       4'bxx_xx, 4'bxx_xx, ... : position <= position + 1'b1;
                //
                //   Check your work with the testbench tb_quad_decoder, then on
                //   the board: turning the disk by hand should change the angle
                //   on the display, up one way and down the other.
                //--------------------------------------------------------------

                // no change, or both channels changed at once: keep the count
                default: position <= position;
            endcase
        end
    end

endmodule
