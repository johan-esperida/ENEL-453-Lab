`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2026 11:21:51 AM
// Design Name: 
// Module Name: output_selector
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


module output_selector(
        input logic pwm_out_sawtooth, pwm_out_triangle,
        input logic triangle_en, sawtooth_en, r2r_enable, buzzer_enable, chirp_enable,
        input logic [2:0] mode_select,
        input logic [7:0] R2R_out_internal,
        input logic buzzer_out_chirp, pwm_out_regular,
        
        output logic pwm_out, buzzer_out,
        output logic [7:0] R2R_out,
        output logic triangle_module_en
    );
    
    logic buzzer_out_internal, pwm_out_internal;
    assign triangle_module_en = triangle_en | r2r_enable;
    // Output multiplexing based on FSM state
    always_comb begin
        pwm_out_internal = mode_select[2] ? pwm_out_sawtooth : pwm_out_triangle;
        pwm_out = (triangle_en | sawtooth_en) ? pwm_out_internal : '0;
        R2R_out = r2r_enable ? R2R_out_internal : '0;
        
        buzzer_out_internal = mode_select[2] ? buzzer_out_chirp : pwm_out_regular;
        buzzer_out = (buzzer_enable | chirp_enable) ? buzzer_out_internal : 0;
    end
endmodule
