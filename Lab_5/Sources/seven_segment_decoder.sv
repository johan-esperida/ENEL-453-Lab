`timescale 1ns / 1ps

// Hexadecimal seven-segment decoder for the active-low Basys3 display.
module seven_segment_decoder (
    input  logic [3:0] data,
    input  logic       decimal_point_on,
    output logic       CA, CB, CC, CD, CE, CF, CG, DP
);

    logic [6:0] segments_on; // ABCDEFG, 1 means illuminated

    always_comb begin
        // Provides a defined blank display if data contains X or Z in simulation.
        segments_on = 7'b0000000;
        case (data)
            4'h0: segments_on = 7'b1111110;
            4'h1: segments_on = 7'b0110000;
            4'h2: segments_on = 7'b1101101;
            4'h3: segments_on = 7'b1111001;
            4'h4: segments_on = 7'b0110011;
            4'h5: segments_on = 7'b1011011;
            4'h6: segments_on = 7'b1011111;
            4'h7: segments_on = 7'b1110000;
            4'h8: segments_on = 7'b1111111;
            4'h9: segments_on = 7'b1111011;
            4'hA: segments_on = 7'b1110111;
            4'hB: segments_on = 7'b0011111; // lowercase b
            4'hC: segments_on = 7'b1001110;
            4'hD: segments_on = 7'b0111101; // lowercase d
            4'hE: segments_on = 7'b1001111;
            4'hF: segments_on = 7'b1000111;
        endcase
    end

    assign {CA, CB, CC, CD, CE, CF, CG} = ~segments_on;
    assign DP = ~decimal_point_on;

endmodule
