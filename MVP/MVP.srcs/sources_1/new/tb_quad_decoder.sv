`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_quad_decoder
//
// Drives the encoder channels A and B through the quadrature sequence and
// checks the position count:
//   - counting up (A leads B) and down (B leads A)
//   - a change of direction
//   - illegal jumps (both channels change at once) must NOT count: both
//     diagonals of the ring, 00 <-> 11 and 10 <-> 01
//   - one full revolution: 2048 counts
//   - reset returns the position to 0
// Prints PASS or FAIL.
//==============================================================================

module tb_quad_decoder;

    import disk_pkg::*;    // POSITION_WIDTH, COUNTS_PER_REV

    logic                             clk    = 0;
    logic                             reset  = 1;
    logic                             a      = 0;
    logic                             b      = 0;
    logic signed [POSITION_WIDTH-1:0] position;
    int                               errors = 0;
    int                               state  = 0;   // index into SEQUENCE

    // Quadrature states in counting-up order: AB = 00, 10, 11, 01.
    localparam logic [1:0] SEQUENCE [4] = '{2'b00, 2'b10, 2'b11, 2'b01};

    quad_decoder DUT (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .position(position)
    );

    always #5 clk = ~clk;   // 100 MHz

    // Move the encoder by "steps" edges: positive = forward, negative = backward.
    task automatic move(int steps);
        repeat (steps < 0 ? -steps : steps) begin
            @(negedge clk);
            state  = (state + (steps > 0 ? 1 : 3)) % 4;
            {a, b} = SEQUENCE[state];
            repeat (2) @(negedge clk);
        end
        @(negedge clk);
    endtask

    task automatic check(int expected, string what);
        if (position !== POSITION_WIDTH'(expected)) begin
            errors++;
            $display("FAIL %s: position = %0d, expected %0d", what, position, expected);
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        reset = 0;
        check(0, "after reset");

        move(10);   check(10,  "10 steps forward");
        move(-25);  check(-15, "25 steps backward");
        move(1);
        move(-1);   check(-15, "change of direction");

        // Illegal jump: both channels flip in the same clock cycle, then back.
        @(negedge clk) {a, b} = ~SEQUENCE[state];
        repeat (3) @(negedge clk);
        {a, b} = SEQUENCE[state];
        repeat (3) @(negedge clk);
        check(-15, "illegal double change ignored");

        // The other diagonal: one step further round the ring, the jump is
        // across the other pair of states.
        move(1);
        @(negedge clk) {a, b} = ~SEQUENCE[state];
        repeat (3) @(negedge clk);
        {a, b} = SEQUENCE[state];
        repeat (3) @(negedge clk);
        check(-14, "the other illegal double change ignored");
        move(-1);

        move(COUNTS_PER_REV); check(-15 + COUNTS_PER_REV, "one revolution forward");

        reset = 1;
        @(negedge clk);
        reset = 0;
        check(0, "reset");

        if (errors == 0) $display("PASS tb_quad_decoder");
        else             $display("FAIL tb_quad_decoder: %0d errors", errors);
        $finish;
    end

endmodule
