`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_bin_to_bcd
//
// Converts every number from 0 to 9999 and compares each digit with the
// answer from ordinary division. Also checks that inputs above 9999 give
// "EEEE". Prints PASS or FAIL.
//==============================================================================

module tb_bin_to_bcd;

    logic        clk    = 0;
    logic        reset  = 1;
    logic [15:0] bin_in = '0;
    logic [15:0] bcd_out;
    int          errors = 0;

    bin_to_bcd DUT (
        .clk(clk),
        .reset(reset),
        .bin_in(bin_in),
        .bcd_out(bcd_out)
    );

    always #5 clk = ~clk;   // 100 MHz

    // Apply a number and wait long enough for a complete conversion
    // (up to 17 cycles to finish the current one, then 17 for this one).
    task automatic check(int value, logic [15:0] expected);
        @(negedge clk);
        bin_in = 16'(value);
        repeat (40) @(negedge clk);
        if (bcd_out !== expected) begin
            errors++;
            if (errors <= 10)
                $display("FAIL %0d: bcd_out = %h, expected %h", value, bcd_out, expected);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        reset = 0;

        for (int n = 0; n <= 9999; n++)
            check(n, {4'(n / 1000), 4'(n / 100 % 10), 4'(n / 10 % 10), 4'(n % 10)});

        check(10000, 16'hEEEE);
        check(65535, 16'hEEEE);
        check(359,   16'h0359);   // and back to a normal value

        if (errors == 0) $display("PASS tb_bin_to_bcd");
        else             $display("FAIL tb_bin_to_bcd: %0d errors", errors);
        $finish;
    end

endmodule
