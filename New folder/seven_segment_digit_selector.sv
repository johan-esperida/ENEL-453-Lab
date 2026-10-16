`timescale 1ns / 1ps

// Time-multiplexes the four Basys3 digits using one system clock and an enable.
module seven_segment_digit_selector (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] digit_select,
    output logic [3:0] an_outputs
);

    logic [16:0] refresh_counter;
    logic [3:0]  selected_digit;

    always_ff @(posedge clk) begin
        if (reset) begin
            refresh_counter <= '0;
            selected_digit  <= 4'b0001;
        end
        else begin
            refresh_counter <= refresh_counter + 1'b1;

            // The counter rollover is an enable, not a derived clock.
            if (refresh_counter == 17'h1FFFF)
                selected_digit <= {selected_digit[2:0], selected_digit[3]};
        end
    end

    assign digit_select = selected_digit;
    assign an_outputs   = ~selected_digit;

endmodule

