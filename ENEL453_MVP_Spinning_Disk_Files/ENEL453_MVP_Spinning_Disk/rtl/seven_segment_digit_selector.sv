`timescale 1ns / 1ps
//==============================================================================
// Module: seven_segment_digit_selector
//
// Purpose
//   Turns the four display digits on one at a time, fast enough that the eye
//   sees all four lit at once ("time multiplexing"). Same job as the Labs 4-6
//   module.
//
//   A free-running 17-bit counter divides the 100 MHz clock. Each time it
//   wraps around to 0, the display moves on to the next digit:
//
//     digit rate   = 100,000,000 / 2^17 = 763 Hz   (one digit every 1.3 ms)
//     refresh rate = 763 / 4            = 191 Hz   (all four digits)
//
// Timing
//
//   digit_index    0      1      2      3      0      1   ...
//   digit_select  0001   0010   0100   1000   0001   0010
//   an_outputs    1110   1101   1011   0111   1110   1101   (active low)
//                 |<-1.3 ms->|
//
// Design note
//   The Labs 4-6 version keeps the one-hot pattern in a ring of four
//   flip-flops. Here a 2-bit digit_index counts 0, 1, 2, 3 and is decoded to
//   one-hot. A 2-bit counter can only ever hold a valid value, so the display
//   can never get stuck with no digit (or two digits) selected.
//
// Inputs
//   clk          : 100 MHz system clock
//   reset        : synchronous, active-high reset. Restarts at the rightmost digit.
//
// Outputs
//   digit_select : one-hot, 1 = this digit is on (bit 0 = rightmost)
//   an_outputs   : anode drive for the display, active low (= ~digit_select)
//
// Internal signals
//   count       : 17-bit free-running counter; wraps every 1.3 ms
//   digit_index : which digit is on now, 0 (rightmost) to 3 (leftmost)
//==============================================================================

module seven_segment_digit_selector (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] digit_select,
    output logic [3:0] an_outputs
);

    // 17 bits: 100 MHz / 2^17 = 763 Hz digit rate.
    localparam int COUNTER_WIDTH = 17;

    logic [COUNTER_WIDTH-1:0] count;
    logic [1:0]  digit_index;

    always_ff @(posedge clk) begin
        if (reset) begin
            count       <= '0;
            digit_index <= '0;
        end else begin
            count <= count + 1'b1;
            if (count == '1)                       // about to wrap: next digit
                digit_index <= digit_index + 1'b1; // 3 + 1 wraps to 0
        end
    end

    // Decode 0, 1, 2, 3 to one-hot 0001, 0010, 0100, 1000.
    assign digit_select = 4'b0001 << digit_index;

    // The Basys3 anodes are active low: 0 turns a digit on.
    assign an_outputs = ~digit_select;

endmodule
