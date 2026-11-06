`timescale 1ns / 1ps
//==============================================================================
// Module: seven_segment_display_subsystem
//
// Purpose
//   Shows four 4-bit values (digit4 digit3 digit2 digit1, left to right) on
//   the Basys3 4-digit 7-segment display. It groups three small modules into
//   one block, as in Labs 4-6:
//
//     seven_segment_digit_selector : turns the digits on one at a time
//     digit_multiplexor            : picks the value of the digit that is on
//     seven_segment_decoder        : draws that value on the segments
//
// Block diagram
//
//                  +--------------------------+  an_outputs
//   clk, reset --->| seven_segment_digit_     |----------------> AN1..AN4
//                  | selector                 |
//                  +--------------------------+
//                               | digit_select (one-hot)
//                               v
//   digit1..4 ---->+--------------------------+  digit_value  +----------------+
//   decimal_point->| digit_multiplexor        |-------------->| seven_segment_ |--> CA..CG
//                  |                          |-------------->| decoder        |--> DP
//                  +--------------------------+  digit_dp     +----------------+
//
//   The display's segment wires CA..CG and DP are shared by all four digits.
//   Each anode AN1..AN4 turns one digit on (active low). Because only one
//   anode is on at a time, the segments show the value of that one digit.
//
// Digit blanking (ADDED for the rotating-disk project; not in Labs 4-6)
//   A digit whose digit_blank bit is 1 stays dark: its anode is held off
//   (1, because the anodes are active low) even when its turn comes.
//   Example: digit_blank = 4'b1000 hides the leftmost digit, so the angle
//   90 degrees shows as " 090" instead of "0090".
//
//     AN4 = an_outputs[3] OR digit_blank[3]     (and the same for AN1..AN3)
//
// Inputs
//   clk            : 100 MHz system clock
//   reset          : synchronous, active-high reset
//   digit1..digit4 : values to show, 0 to F (digit1 = rightmost)
//   decimal_point  : decimal points, bit 0 = rightmost digit, 1 = on
//   digit_blank    : 1 = keep this digit dark, bit 0 = rightmost digit (ADDED)
//
// Outputs
//   CA..CG         : segment outputs to the display (active low)
//   DP             : decimal point output to the display (active low)
//   AN1..AN4       : anode outputs to the display (active low, AN1 = rightmost)
//
// Internal signals
//   digit_select : one-hot code for the digit that is on now
//   an_outputs   : the matching active-low anode pattern
//   digit_value  : the value of the digit that is on now
//   digit_dp     : the decimal point of the digit that is on now
//==============================================================================

module seven_segment_display_subsystem (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] digit1,
    input  logic [3:0] digit2,
    input  logic [3:0] digit3,
    input  logic [3:0] digit4,
    input  logic [3:0] decimal_point,
    input  logic [3:0] digit_blank,      // ADDED for the disk project
    output logic       CA, CB, CC, CD, CE, CF, CG,
    output logic       DP,
    output logic       AN1, AN2, AN3, AN4
);

    logic [3:0] digit_select;
    logic [3:0] an_outputs;
    logic [3:0] digit_value;
    logic       digit_dp;

    // Turn the four digits on one at a time (about 763 Hz per digit).
    seven_segment_digit_selector DIGIT_SELECTOR (
        .clk(clk),                      // system clock
        .reset(reset),                  // synchronous reset
        .digit_select(digit_select),    // one-hot: which digit is on
        .an_outputs(an_outputs)         // active-low anode pattern
    );

    // Pick the value and decimal point of the digit that is on.
    digit_multiplexor DIGIT_MUX (
        .digit1(digit1),                // rightmost digit value
        .digit2(digit2),
        .digit3(digit3),
        .digit4(digit4),                // leftmost digit value
        .decimal_point(decimal_point),  // decimal points, bit 0 = rightmost
        .selector(digit_select),        // which digit is on
        .digit(digit_value),            // value of the digit that is on
        .dp(digit_dp)                   // decimal point of the digit that is on
    );

    // Draw the selected value on the shared segment wires.
    seven_segment_decoder SEGMENT_DECODER (
        .data(digit_value),             // value to draw, 0 to F
        .dp_in(digit_dp),               // 1 = decimal point on
        .CA(CA),                        // segment outputs (active low)
        .CB(CB),
        .CC(CC),
        .CD(CD),
        .CE(CE),
        .CF(CF),
        .CG(CG),
        .DP(DP)                         // decimal point output (active low)
    );

    // One anode per digit: AN1 is the rightmost digit. A blanked digit keeps
    // its anode off (1). The "| digit_blank[...]" terms were ADDED for the
    // disk project; without blanking, ANx = an_outputs[x-1] as in Labs 4-6.
    assign AN1 = an_outputs[0] | digit_blank[0];
    assign AN2 = an_outputs[1] | digit_blank[1];
    assign AN3 = an_outputs[2] | digit_blank[2];
    assign AN4 = an_outputs[3] | digit_blank[3];

endmodule
