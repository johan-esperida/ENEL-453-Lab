`timescale 1ns / 1ps
//==============================================================================
// Module: seven_segment_decoder
//
// Purpose
//   Turns a 4-bit number (0 to F hexadecimal) into the pattern of segments
//   that draws it on one 7-segment digit. Same as the Labs 4-6 decoder.
//
// Segment names (the decimal point DP is at the bottom right):
//
//          A
//        -----
//     F |     | B
//       |  G  |
//        -----
//     E |     | C
//       |     |
//        -----   . DP
//          D
//
// Active-low outputs
//   On the Basys3, a segment lights when its signal is 0. The table below is
//   written with 1 = lit, because that is easier to read, and every output is
//   inverted at the end.
//
//   Example: digit 7 lights A, B and C -> segments = ABCDEFG = 111_0000
//            -> outputs CA, CB, CC = 0 (lit), CD ... CG = 1 (dark)
//
// Inputs
//   data   : 4-bit value to show, 0 to F
//   dp_in  : 1 = light the decimal point
//
// Outputs
//   CA..CG : segment A..G outputs to the display (active low)
//   DP     : decimal point output to the display (active low)
//
// Internal signals
//   segments : the 7-segment pattern, ABCDEFG, 1 = lit
//==============================================================================

module seven_segment_decoder (
    input  logic [3:0] data,
    input  logic       dp_in,
    output logic       CA, CB, CC, CD, CE, CF, CG,
    output logic       DP
);

    logic [6:0] segments;

    always_comb begin
        case (data)                     //  ABCDEFG   (1 = lit)
            4'h0:    segments = 7'b1111110;
            4'h1:    segments = 7'b0110000;
            4'h2:    segments = 7'b1101101;
            4'h3:    segments = 7'b1111001;
            4'h4:    segments = 7'b0110011;
            4'h5:    segments = 7'b1011011;
            4'h6:    segments = 7'b1011111;
            4'h7:    segments = 7'b1110000;
            4'h8:    segments = 7'b1111111;
            4'h9:    segments = 7'b1111011;
            4'hA:    segments = 7'b1110111;
            4'hB:    segments = 7'b0011111;  // lower-case b
            4'hC:    segments = 7'b1001110;
            4'hD:    segments = 7'b0111101;  // lower-case d
            4'hE:    segments = 7'b1001111;
            default: segments = 7'b1000111;  // F
        endcase
    end

    // The display is active low: invert every segment.
    assign {CA, CB, CC, CD, CE, CF, CG} = ~segments;
    assign DP = ~dp_in;

endmodule
