`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2026 01:38:20 PM
// Design Name: 
// Module Name: Buzzer_Var_PWM
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


module buzzer_chirp #(
    parameter int CLOCK_FREQ = 100_000_000, // System clock frequency in Hz
    parameter int BUZZER_FREQ_MAX = 10000,        // Desired buzzer frequency in Hz
    parameter int BUZZER_FREQ_MIN = 500,        // Desired buzzer frequency in Hz
    parameter int CHIRP_PERIOD_SECONDS = 2
) (
    input  logic clk,    // Clock input
    input  logic reset,  // Active-high reset
    input  logic enable, // Active-high enable
    output logic pwm_out // PWM signal output for buzzer
);

    // Downcounter parameters
    localparam int PERIOD = CLOCK_FREQ / BUZZER_FREQ_MAX; // Calculate the period for half the buzzer frequency
    localparam int PERIOD_FREQ = CLOCK_FREQ / BUZZER_FREQ_MIN / 2; // Calculate the period for half the buzzer frequency
    localparam int CHIRP_STEP_NUMBER = BUZZER_FREQ_MAX / BUZZER_FREQ_MIN;
    localparam int CHIRP_STEP_PERIOD = CHIRP_PERIOD_SECONDS * BUZZER_FREQ_MAX / (CHIRP_STEP_NUMBER); 
   


    
    //counter for steps in total period
    localparam int STEP_COUNT_WIDTH = $clog2(CHIRP_STEP_NUMBER + 1);
    logic [STEP_COUNT_WIDTH-1:0] period_count = 1;
    logic [STEP_COUNT_WIDTH-1:0] pwm_count = 0;

    
    //counter for period of steps
    localparam int PERIOD_COUNT_WIDTH = $clog2(CHIRP_STEP_PERIOD + 1);
    logic [PERIOD_COUNT_WIDTH-1:0] step_period_count;
    


    logic zero;  // Signal to indicate when the counter reaches zero
    logic pwm_out_zero;

    // Instantiate the downcounter to generate the desired frequency
    downcounter #(
        .PERIOD(PERIOD)
    ) downcounter_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .count_step(enable),
        .zero(zero) // Pulses at the desired frequency
    );
    
    //generate the varying pwm signal
    downcounter #(
        .PERIOD(PERIOD_FREQ)
    ) downcounter_inst_pwm (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .count_step(period_count),
        .zero(pwm_out_zero) // Pulses at the desired frequency
    );
   
    
    
    //counter for steps and period
    always_ff @(posedge clk) begin
        if (reset) begin
            step_period_count <= 1;
            period_count <= 1;
            pwm_count <= 0;
            
        end else if (zero) begin
        
            if (step_period_count >= CHIRP_STEP_PERIOD) begin
                step_period_count <= 1;
            
                //period handling
                if (period_count >= CHIRP_STEP_NUMBER) 
                    period_count <= 1;
                else
                    period_count <= period_count + 1;
        
            end else 
                step_period_count <= step_period_count + 1; // Count up for step period   
        end
    end
    
    //generate pwm oscillation
    always_ff @(posedge clk) begin
        if (reset)
            pwm_out <= 0;
        else if (pwm_out_zero)
            pwm_out <= ~pwm_out; // Toggle the PWM output
    end
    
endmodule

