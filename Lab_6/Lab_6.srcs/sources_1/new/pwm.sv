module pwm #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    input  logic [WIDTH-1:0] duty_cycle,
    output logic             pwm_out
);

    // The counter has 2**WIDTH - 1 states. For WIDTH = 8, it counts
    // from 0 through 254, giving a PWM period of 255 clock cycles.
    // Therefore duty_cycle ranges naturally from 0/255 to 255/255.
    localparam logic [WIDTH-1:0] MAX_CODE = {WIDTH{1'b1}};

    logic [WIDTH-1:0] counter;

    always_ff @(posedge clk) begin
        if (reset || !enable)
            counter <= '0;
        else if (counter == MAX_CODE - 1'b1)
            counter <= '0;
        else
            counter <= counter + 1'b1;
    end

    // This single comparison provides the complete range:
    // duty_cycle = 0        ->   0% duty cycle
    // duty_cycle = MAX_CODE -> 100% duty cycle
    always_comb begin
        pwm_out = enable && (counter < duty_cycle);
    end

endmodule
