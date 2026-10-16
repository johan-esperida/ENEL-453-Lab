`timescale 1ns / 1ps

// Selects one of the four Lab 5 representations for the display and LEDs.
module display_mode_selector (
    input  logic [1:0]  display_select,
    input  logic [11:0] raw_adc_data,       // 12-bit XADC conversion code
    input  logic [15:0] averaged_adc_data,  // high-resolution left-aligned value
    input  logic [15:0] scaled_adc_data,    // binary value in tenths of a mV
    input  logic [15:0] bcd_data,
    output logic [15:0] display_data,
    output logic [15:0] led_data,
    output logic [3:0]  decimal_point
);

    always_comb begin
        display_data  = 16'h0000;
        led_data      = 16'h0000;
        decimal_point = 4'b0000;

        case (display_select)
            2'b00: begin
                // Show the raw 12-bit code as 0000 through 0FFF.
                display_data = {4'b0000, raw_adc_data};
                led_data     = {4'b0000, raw_adc_data};
            end

            2'b01: begin
                display_data = averaged_adc_data;
                led_data     = averaged_adc_data;
            end

            2'b10: begin
                display_data = scaled_adc_data;
                led_data     = scaled_adc_data;
            end

            2'b11: begin
                display_data  = bcd_data;
                led_data      = scaled_adc_data;
                // Decimal point between the tens and units BCD digits: 999.9.
                decimal_point = 4'b0010;
            end

        endcase
    end

endmodule
