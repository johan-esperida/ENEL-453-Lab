`timescale 1ns / 1ps

// Converts a 16-bit unsigned binary value to four BCD digits.
// Values above 9999 produce 16'hEEEE. Conversion is continuously repeated and
// requires 18 clocks; this is far faster than the XADC sample interval.
module bin_to_bcd (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] bin_in,
    output logic [15:0] bcd_out
);

    logic [31:0] scratch, next_scratch;
    logic [4:0]  count, next_count;
    logic [15:0] next_bcd_out;

    always_ff @(posedge clk) begin
        if (reset) begin
            scratch <= '0;
            count   <= '0;
            bcd_out <= '0;
        end
        else begin
            scratch <= next_scratch;
            count   <= next_count;
            bcd_out <= next_bcd_out;
        end
    end

    always_comb begin
        next_scratch = scratch;
        next_count   = count;
        next_bcd_out = bcd_out;

        if (bin_in > 16'd9999) begin
            next_scratch = '0;
            next_count   = '0;
            next_bcd_out = 16'hEEEE;
        end
        else begin
            case (count)
                5'd0: begin
                    next_scratch = {16'b0, bin_in};
                    next_count   = 5'd1;
                end

                5'd1,  5'd2,  5'd3,  5'd4,
                5'd5,  5'd6,  5'd7,  5'd8,
                5'd9,  5'd10, 5'd11, 5'd12,
                5'd13, 5'd14, 5'd15, 5'd16: begin
                    if (next_scratch[31:28] >= 5)
                        next_scratch[31:28] = next_scratch[31:28] + 3;
                    if (next_scratch[27:24] >= 5)
                        next_scratch[27:24] = next_scratch[27:24] + 3;
                    if (next_scratch[23:20] >= 5)
                        next_scratch[23:20] = next_scratch[23:20] + 3;
                    if (next_scratch[19:16] >= 5)
                        next_scratch[19:16] = next_scratch[19:16] + 3;

                    next_scratch = {next_scratch[30:0], 1'b0};
                    next_count   = count + 1'b1;
                end

                5'd17: begin
                    next_bcd_out = scratch[31:16];
                    next_count   = '0;
                end

                default: begin
                    next_scratch = '0;
                    next_count   = '0;
                end
            endcase
        end
    end

endmodule

