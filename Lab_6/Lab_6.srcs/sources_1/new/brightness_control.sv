`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2026 11:40:32 AM
// Design Name: 
// Module Name: brightness_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module brightness_control(
    input logic pwm_out,
    input logic [15:0] scaled_adc_data,
    input logic AN1_internal, AN2_internal, AN3_internal, AN4_internal,
    input logic triangle_en, sawtooth_en,
    output logic [15:0] led,
    output logic AN1, AN2, AN3, AN4
    );
    
    assign led = pwm_out ? scaled_adc_data : '0;
    always_comb begin
        if(triangle_en | sawtooth_en) begin
            AN1 = pwm_out ? AN1_internal : '1;
            AN2 = pwm_out ? AN2_internal : '1;
            AN3 = pwm_out ? AN3_internal : '1;
            AN4 = pwm_out ? AN4_internal : '1;
        end
        else begin
            AN1 = AN1_internal;
            AN2 = AN2_internal;
            AN3 = AN3_internal;
            AN4 = AN4_internal;
        end
     end
endmodule
