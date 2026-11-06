`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_position_to_degrees
//
// Tries every 16-bit position, -32,768 to +32,767, and compares the result
// with degrees = (position modulo 2048) x 360 / 2048, rounded down.
// Prints PASS or FAIL.
//==============================================================================

module tb_position_to_degrees;

    import disk_pkg::*;    // COUNTS_PER_REV, POSITION_WIDTH, DEGREES_WIDTH

    logic signed [POSITION_WIDTH-1:0] position = '0;
    logic        [DEGREES_WIDTH-1:0]  degrees;
    int                               errors   = 0;
    int                               expected;

    position_to_degrees DUT (
        .position(position),
        .degrees(degrees)
    );

    initial begin
        for (int p = -32768; p <= 32767; p++) begin
            position = POSITION_WIDTH'(p);
            #1;
            // Modulo that is always positive, even for negative positions.
            expected = ((p % COUNTS_PER_REV + COUNTS_PER_REV) % COUNTS_PER_REV)
                       * 360 / COUNTS_PER_REV;
            if (degrees !== DEGREES_WIDTH'(expected)) begin
                errors++;
                if (errors <= 10)
                    $display("FAIL position %0d: degrees = %0d, expected %0d",
                             p, degrees, expected);
            end
        end

        if (errors == 0) $display("PASS tb_position_to_degrees");
        else             $display("FAIL tb_position_to_degrees: %0d errors", errors);
        $finish;
    end

endmodule
