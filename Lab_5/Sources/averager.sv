`timescale 1ns / 1ps

// Moving average of the most recent 2**N enabled samples.
//
// On every EN pulse:
//   1. The newest sample enters the shift register.
//   2. The oldest sample leaves the shift register.
//   3. The running sum adds the newest sample and subtracts the oldest.
//   4. Q updates to the new moving average.
//
// When EN is low, all state holds.
module averager #(
    parameter int N          = 8,   // 2**8 = 256 samples
    parameter int DATA_WIDTH = 16
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  EN,
    input  logic [DATA_WIDTH-1:0] Din,
    output logic [DATA_WIDTH-1:0] Q
);

    localparam int WINDOW_SIZE = 2**N;
    localparam int SUM_WIDTH   = DATA_WIDTH + N;

    logic [DATA_WIDTH-1:0] sample_history [0:WINDOW_SIZE-1];
    logic [SUM_WIDTH-1:0]  sum;

    logic [SUM_WIDTH-1:0] newest_sample;
    logic [SUM_WIDTH-1:0] oldest_sample;

    assign newest_sample = {{N{1'b0}}, Din};

    assign oldest_sample =
        {{N{1'b0}}, sample_history[WINDOW_SIZE-1]};

    // Divide the running sum by 2**N.
    assign Q = sum[SUM_WIDTH-1:N];

    always_ff @(posedge clk) begin
        if (reset) begin
            sum <= '0;

            // Fill the initial averaging window with zeros.
            for (int i = 0; i < WINDOW_SIZE; i++) begin
                sample_history[i] <= '0;
            end
        end
        else if (EN) begin
            // Shift the sample history.
            for (int i = WINDOW_SIZE-1; i > 0; i--) begin
                sample_history[i] <= sample_history[i-1];
            end

            sample_history[0] <= Din;

            // Update the moving sum.
            sum <= sum + newest_sample - oldest_sample;
        end
    end

endmodule