`timescale 1ns / 1ps
//==============================================================================
// Module: digit_multiplexor
//
// Purpose
//   The four digits of the Basys3 display share the same seven segment wires,
//   so only one digit can be shown at a time. This multiplexer picks which
//   digit's value (and decimal point) goes to the segment decoder, following
//   the one-hot "selector" from the digit selector. Same job as the Labs 4-6
//   module, with digit names that are not tied to a stopwatch.
//
//   selector   chosen digit         position on the display
//   --------   ------------------   -----------------------
//     0001     digit1, dp bit 0     rightmost
//     0010     digit2, dp bit 1
//     0100     digit3, dp bit 2
//     1000     digit4, dp bit 3     leftmost
//     other    0, decimal point off (never happens: selector is one-hot)
//
// Block diagram
//
//   digit1 --->+-------+
//   digit2 --->|  4:1  |
//   digit3 --->|  mux  |---> digit
//   digit4 --->|       |
//              +-------+
//                  ^
//   selector ------+------> (same selection for decimal_point ---> dp)
//
// Inputs
//   digit1..digit4 : 4-bit values for the four digits (digit1 = rightmost)
//   decimal_point  : decimal point for each digit, bit 0 = rightmost, 1 = on
//   selector       : one-hot digit select from seven_segment_digit_selector
//
// Outputs
//   digit          : the selected digit's value
//   dp             : the selected digit's decimal point
//==============================================================================

module digit_multiplexor (
    input  logic [3:0] digit1,
    input  logic [3:0] digit2,
    input  logic [3:0] digit3,
    input  logic [3:0] digit4,
    input  logic [3:0] decimal_point,
    input  logic [3:0] selector,
    output logic [3:0] digit,
    output logic       dp
);

    always_comb begin
        case (selector)
            4'b0001: begin digit = digit1; dp = decimal_point[0]; end
            4'b0010: begin digit = digit2; dp = decimal_point[1]; end
            4'b0100: begin digit = digit3; dp = decimal_point[2]; end
            4'b1000: begin digit = digit4; dp = decimal_point[3]; end
            default: begin digit = 4'h0;   dp = 1'b0;             end
        endcase
    end

endmodule
