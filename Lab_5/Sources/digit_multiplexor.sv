`timescale 1ns / 1ps

module digit_multiplexor (
    input  logic [3:0] digit_0,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_2,
    input  logic [3:0] digit_3,
    input  logic [3:0] selector,
    input  logic [3:0] decimal_point,
    output logic [3:0] digit_to_display,
    output logic       decimal_point_on
);

    always_comb begin
        digit_to_display = 4'h0;
        decimal_point_on = 1'b0;

        case (selector)
            4'b0001: begin
                digit_to_display = digit_0;
                decimal_point_on = decimal_point[0];
            end
            4'b0010: begin
                digit_to_display = digit_1;
                decimal_point_on = decimal_point[1];
            end
            4'b0100: begin
                digit_to_display = digit_2;
                decimal_point_on = decimal_point[2];
            end
            4'b1000: begin
                digit_to_display = digit_3;
                decimal_point_on = decimal_point[3];
            end
            default: begin
                digit_to_display = 4'h0;
                decimal_point_on = 1'b0;
            end
        endcase
    end

endmodule

