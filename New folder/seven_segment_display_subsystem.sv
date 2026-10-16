`timescale 1ns / 1ps

module seven_segment_display_subsystem (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] digit_0,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_2,
    input  logic [3:0] digit_3,
    input  logic [3:0] decimal_point,
    output logic       CA, CB, CC, CD, CE, CF, CG, DP,
    output logic       AN1, AN2, AN3, AN4
);

    logic [3:0] digit_select;
    logic [3:0] an_outputs;
    logic [3:0] digit_to_display;
    logic       decimal_point_on;

    digit_multiplexor DIGIT_MUX (
        .digit_0(digit_0),
        .digit_1(digit_1),
        .digit_2(digit_2),
        .digit_3(digit_3),
        .selector(digit_select),
        .decimal_point(decimal_point),
        .digit_to_display(digit_to_display),
        .decimal_point_on(decimal_point_on)
    );

    seven_segment_digit_selector DIGIT_SELECTOR (
        .clk(clk),
        .reset(reset),
        .digit_select(digit_select),
        .an_outputs(an_outputs)
    );

    seven_segment_decoder SEGMENT_DECODER (
        .data(digit_to_display),
        .decimal_point_on(decimal_point_on),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD),
        .CE(CE), .CF(CF), .CG(CG), .DP(DP)
    );

    assign {AN4, AN3, AN2, AN1} = an_outputs;

endmodule

