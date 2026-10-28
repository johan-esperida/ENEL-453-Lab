module output_mode_fsm (
    input  logic clk,
    input  logic reset,
    input  logic [2:0] mode_select,  // Two-bit input for mode selection
    output logic r2r_enable,
    output logic buzzer_enable,
    output logic sawtooth_en,
    output logic triangle_en,     
    output logic chirp_en
);
    typedef enum logic [2:0] {
        OFF_MODE = 3'b000,
        TRIANGLE_MODE = 3'b001,
        R2R_MODE = 3'b010,
        BUZZER_MODE = 3'b011,
        SAW_MODE = 3'b101,
        CHIRP_MODE = 3'b111
    } statetype;

    statetype current_state, next_state;
    
    
    // State register
    always_ff @(posedge clk) begin
        if (reset)
            current_state <= OFF_MODE;
        else
            current_state <= next_state;
    end

    // Next state logic
    always_comb begin
        next_state = statetype'(mode_select);  // Directly use mode_select as the next state
    end

    // Output logic
    always_comb begin
        r2r_enable = 0;
        buzzer_enable = 0;
        sawtooth_en = 0;
        triangle_en = 0;
        chirp_en = 0;
        case (current_state)
            TRIANGLE_MODE:   triangle_en = 1; 
            R2R_MODE:    r2r_enable = 1;
            BUZZER_MODE: buzzer_enable = 1;
            SAW_MODE:    sawtooth_en = 1;
            CHIRP_MODE:  chirp_en = 1;
            OFF_MODE:    ;
            default:     ; // All outputs remain 0
        endcase
    end
endmodule