// ADC processing subsystem
//
// The XADC result is a 12-bit value left-aligned in a 16-bit word, so its
// largest valid value is 16'hFFF0. The scaling calculation maps 16'hFFF0 to
// 9999, representing 999.9 mV on the four-digit BCD display.
module adc_processing #(
    parameter logic [16:0] SCALING_FACTOR = 17'd5001,
    parameter int          SHIFT_FACTOR   = 15
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        ready,
    input  logic [15:0] data,
    output logic [15:0] scaled_adc_data,
    output logic [15:0] averaged_adc_data,
    output logic        ready_pulse
);

    logic        ready_r;
    logic [32:0] scaled_product;

    // Convert a rising edge on ready into a one-clock enable pulse.
    always_ff @(posedge clk) begin
        if (reset)
            ready_r <= 1'b0;
        else
            ready_r <= ready;
    end

    assign ready_pulse = ready && !ready_r;

    // The averager accepts one new ADC sample on every ready_pulse.
    averager #(
        .power(8), // 2**8 = 256 samples
        .N(16)
    ) AVERAGER (
        .clk(clk),
        .reset(reset),
        .EN(ready_pulse),
        .Din(data),
        .Q(averaged_adc_data)
    );

    // 5001/2**15 closely approximates 9999/16'hFFF0:
    //     16'hFFF0 * 5001 >> 15 = 9999
    // The 33-bit signal holds the complete 16-bit by 17-bit product.
    assign scaled_product = averaged_adc_data * SCALING_FACTOR;

    always_ff @(posedge clk) begin
        if (reset)
            scaled_adc_data <= '0;
        else if (ready_pulse)
            scaled_adc_data <= scaled_product >> SHIFT_FACTOR;
    end

endmodule
