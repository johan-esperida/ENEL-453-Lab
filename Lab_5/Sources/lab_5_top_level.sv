`timescale 1ns / 1ps

// Correct working starter design for Lab 5.
//
// This version intentionally places the XADC, averaging, and scaling logic in
// the top level. The lab exercise asks students to refactor those elements into
// an ADC subsystem while preserving behaviour.
module lab_5_top_level
    (
    input  logic       clk,
    input  logic       reset,
    input  logic [1:0] display_select,
    input              vauxp15,
    input              vauxn15,
    output logic       CA, CB, CC, CD, CE, CF, CG, DP,
    output logic       AN1, AN2, AN3, AN4,
    output logic [15:0] led
);

    localparam logic [6:0] CHANNEL_ADDRESS = 7'h1F;

    logic        xadc_enable;
    logic        xadc_data_ready;
    logic [15:0] raw_adc_data;
    logic [15:0] averaged_adc_data;
    logic [31:0] scaled_product;
    logic [15:0] scaled_adc_data;
    logic [15:0] bcd_data;
    logic [15:0] display_data;
    logic [3:0]  decimal_point;

    

    bin_to_bcd BIN_TO_BCD (
        .clk(clk),
        .reset(reset),
        .bin_in(scaled_adc_data),
        .bcd_out(bcd_data)
    );

    display_mode_selector DISPLAY_SELECTOR (
        .display_select(display_select),
        .raw_adc_data(raw_adc_data[15:4]),
        .averaged_adc_data(averaged_adc_data),
        .scaled_adc_data(scaled_adc_data),
        .bcd_data(bcd_data),
        .display_data(display_data),
        .led_data(led),
        .decimal_point(decimal_point)
    );

    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY (
        .clk(clk),
        .reset(reset),
        .digit_0(display_data[3:0]),
        .digit_1(display_data[7:4]),
        .digit_2(display_data[11:8]),
        .digit_3(display_data[15:12]),
        .decimal_point(decimal_point),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD),
        .CE(CE), .CF(CF), .CG(CG), .DP(DP),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4)
    );

endmodule
