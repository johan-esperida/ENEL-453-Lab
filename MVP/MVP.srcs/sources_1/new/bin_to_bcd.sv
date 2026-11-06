`timescale 1ns / 1ps
//==============================================================================
// Module: bin_to_bcd
//
// Purpose
//   Converts a 16-bit binary number (0 to 9999) into four BCD digits, one
//   decimal digit per 4 bits, ready for the 7-segment display:
//
//     bin_in  = 359 = 0000_0001_0110_0111 (binary)
//     bcd_out = 0359 = 0000_0011_0101_1001 (BCD: digits 0, 3, 5, 9)
//
//   Same ports and timing as the bin_to_bcd module from Labs 4-6. Inputs
//   above 9999 do not fit in four digits; they display as "EEEE".
//
//   For ENEL 453 you do not need to know this algorithm. You should know how
//   to convert between binary and BCD by hand.
//
// Algorithm: "double dabble" (shift and add 3), one bit per clock cycle
//   The binary bits are shifted, most significant first, into a BCD register.
//   Shifting left doubles the value. Before each shift, any BCD digit that is
//   5 or more gets 3 added, so that when it doubles it carries correctly into
//   the next digit (5 + 3 = 8 = 1000, which shifts to 1_0000: a carry of 1 and
//   a 0 left behind, exactly as 5 x 2 = 10 in decimal).
//
//   Example: 13 (binary 1101) needs only the last 4 of the 16 shifts:
//
//     step                  bcd (tens  ones)   binary bits left
//     ----                  ----------------   ----------------
//     start                       0000 0000    1101
//     shift                       0000 0001    101
//     shift                       0000 0011    01
//     shift                       0000 0110    1
//     ones = 6 >= 5: add 3        0000 1001
//     shift                       0001 0011    (done: 1 3 = 13)
//
// Timing
//   One conversion takes 17 clock cycles: 1 to load bin_in, then 16 shifts.
//   bcd_out updates at the end of each conversion and holds its value until
//   the next one finishes, then a new conversion starts at once. At 100 MHz
//   that is a fresh result every 170 ns, far faster than the eye can see.
//
// Inputs
//   clk     : 100 MHz system clock
//   reset   : synchronous, active-high reset. Clears the output.
//   bin_in  : binary number to convert, 0 to 9999
//
// Outputs
//   bcd_out : four BCD digits: [15:12] thousands, [11:8] hundreds,
//             [7:4] tens, [3:0] ones. 16'hEEEE if bin_in > 9999.
//
// Internal signals
//   binary      : binary bits not yet shifted into bcd
//   bcd         : the four BCD digits being built
//   bcd_plus_3  : bcd with 3 added to each digit that is 5 or more
//   shifts_left : shifts still to do in this conversion (16 down to 0)
//   too_big     : 1 if the number being converted is above 9999
//==============================================================================

module bin_to_bcd (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] bin_in,
    output logic [15:0] bcd_out
);

    localparam logic [15:0] MAX_VALUE = 16'd9999;   // largest number four digits can show

    logic [15:0] binary;
    logic [15:0] bcd;
    logic [15:0] bcd_plus_3;
    logic [4:0]  shifts_left;
    logic        too_big;

    // Add 3 to each BCD digit that is 5 or more (the "dabble" step).
    assign bcd_plus_3[3:0]   = (bcd[3:0]   >= 4'd5) ? bcd[3:0]   + 4'd3 : bcd[3:0];
    assign bcd_plus_3[7:4]   = (bcd[7:4]   >= 4'd5) ? bcd[7:4]   + 4'd3 : bcd[7:4];
    assign bcd_plus_3[11:8]  = (bcd[11:8]  >= 4'd5) ? bcd[11:8]  + 4'd3 : bcd[11:8];
    assign bcd_plus_3[15:12] = (bcd[15:12] >= 4'd5) ? bcd[15:12] + 4'd3 : bcd[15:12];

    always_ff @(posedge clk) begin
        if (reset) begin
            binary      <= '0;
            bcd         <= '0;
            shifts_left <= '0;
            too_big     <= 1'b0;
            bcd_out     <= '0;
        end else if (shifts_left == 0) begin
            // Load: start a new conversion.
            binary      <= bin_in;
            bcd         <= '0;
            shifts_left <= 5'd16;
            too_big     <= (bin_in > MAX_VALUE);
        end else begin
            // Shift: move the top binary bit into the bottom of the BCD digits
            // (the "double" step).
            bcd         <= {bcd_plus_3[14:0], binary[15]};
            binary      <= {binary[14:0], 1'b0};
            shifts_left <= shifts_left - 1'b1;

            // Last shift: the conversion is complete.
            if (shifts_left == 1)
                bcd_out <= too_big ? 16'hEEEE : {bcd_plus_3[14:0], binary[15]};
        end
    end

endmodule
