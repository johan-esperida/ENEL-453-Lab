`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_debounce
//
// The clock is scaled down to 1 MHz and the stable time to 1 ms, so the
// output should change 1000 clock cycles after the input stops bouncing.
// Checks:
//   - bouncing does not reach the output
//   - the output rises only after the input has been steady for the stable time
//   - a short glitch, shorter than the stable time, is ignored
//   - the release is debounced the same way
// Prints PASS or FAIL.
//==============================================================================

module tb_debounce;

    localparam int CLK_FREQ  = 1_000_000;   // 1 MHz: 1 us per clock cycle
    localparam int STABLE_MS = 1;           // 1 ms = 1000 clock cycles

    logic clk    = 0;
    logic reset  = 1;
    logic button = 0;
    logic result;
    int   errors = 0;

    debounce #(
        .CLK_FREQ(CLK_FREQ),
        .STABLE_TIME_MS(STABLE_MS)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .button(button),
        .result(result)
    );

    always #500 clk = ~clk;   // 1 MHz

    task automatic wait_cycles(int n);
        repeat (n) @(negedge clk);
    endtask

    // Toggle the button every 50 cycles, "times" times, ending at "final_level".
    task automatic bounce(int times, logic final_level);
        repeat (times) begin
            button = ~button;
            wait_cycles(50);
        end
        button = final_level;
    endtask

    task automatic check(logic expected, string what);
        if (result !== expected) begin
            errors++;
            $display("FAIL %s: result = %b, expected %b", what, result, expected);
        end
    endtask

    initial begin
        wait_cycles(3);
        reset = 0;
        wait_cycles(10);
        check(0, "after reset");

        // Press with bounce: the output stays 0 while bouncing ...
        bounce(9, 1);
        check(0, "while bouncing");
        // ... and for most of the stable time after it ...
        wait_cycles(900);
        check(0, "steady, but not yet for 1 ms");
        // ... then follows the button.
        wait_cycles(200);
        check(1, "steady for 1 ms: pressed");

        // A 500-cycle glitch (shorter than 1 ms) must be ignored.
        button = 0;
        wait_cycles(500);
        button = 1;
        wait_cycles(1500);
        check(1, "short glitch ignored");

        // Release with bounce.
        bounce(9, 0);
        wait_cycles(1200);
        check(0, "released");

        if (errors == 0) $display("PASS tb_debounce");
        else             $display("FAIL tb_debounce: %0d errors", errors);
        $finish;
    end

endmodule
