`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_p_controller  (the reuse compliance testbench)
//
// p_controller is written to be reused, unchanged: inside the PI controller
// (enhancement E4 of the Final Design Lab Project), or for another plant.
// This testbench checks that it can be: it instantiates the SAME file four
// times, with different parameters, and checks each one.
//
//   instance    parameters                               used like
//   ----------  ---------------------------------------  ----------------------
//   DUT_DISK    16-bit inputs, limits -255 ... +255      the rotating disk
//   DUT_FREE    defaults: no limits, full-width output   the P part inside PI
//   DUT_OTHER   12-bit inputs, limits -40 ... +200,      another plant: uneven
//               FRAC_BITS = 2 (gain = kp / 4)            limits, a fractional gain
//   DUT_SAME    exactly DUT_DISK's parameters            (second disk copy, for
//                                                         the reset check)
//
// Checks
//   Disk (DUT_DISK): positive and negative errors at several gains; limiting
//     at +255 and -255, including the largest possible errors; zero error and
//     zero gain; the error output and its sign (reference - measured); holding
//     between sample_ticks; reset.
//   Limits are per instance (DUT_FREE): the inputs that DUT_DISK limits to
//     +255 come out unlimited here. A limit written into the module as a
//     constant fails this check.
//   Full-width product (DUT_FREE): the largest errors at the largest gain give
//     exactly +983,025 and -983,025. A product cut down to fewer bits wraps
//     around and fails.
//   Another plant (DUT_OTHER): the uneven limits, and the fractional gain,
//     including how ">>>" rounds a negative number (down).
// Prints PASS or FAIL, with the number of checks.
//==============================================================================

module tb_p_controller;

    logic clk         = 0;
    logic reset       = 1;
    logic sample_tick = 0;
    int   checks      = 0;
    int   errors      = 0;

    // DUT_DISK and DUT_SAME: as disk_top uses it.
    logic signed [15:0] disk_reference = '0;
    logic signed [15:0] disk_measured  = '0;
    logic        [3:0]  disk_kp        = '0;
    logic signed [16:0] disk_error;
    logic signed [8:0]  disk_action;
    logic signed [16:0] same_error;
    logic signed [8:0]  same_action;

    // DUT_FREE: the default parameters (16-bit inputs, 4-bit kp, 22-bit output, no limits).
    logic signed [16:0] free_error;
    logic signed [21:0] free_action;

    // DUT_OTHER: 12-bit inputs (an ADC reading), limits -40 ... +200, gain kp / 4.
    logic signed [11:0] other_reference = '0;
    logic signed [11:0] other_measured  = '0;
    logic        [3:0]  other_kp        = '0;
    logic signed [12:0] other_error;
    logic signed [8:0]  other_action;

    p_controller #(
        .IN_WIDTH(16),
        .KP_WIDTH(4),
        .OUT_WIDTH(9),
        .OUT_MAX(255),
        .OUT_MIN(-255)
    ) DUT_DISK (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .reference(disk_reference),
        .measured(disk_measured),
        .kp(disk_kp),
        .error(disk_error),
        .p_action(disk_action)
    );

    p_controller DUT_FREE (                // every parameter at its default
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .reference(disk_reference),
        .measured(disk_measured),
        .kp(disk_kp),
        .error(free_error),
        .p_action(free_action)
    );

    p_controller #(
        .IN_WIDTH(12),
        .KP_WIDTH(4),
        .FRAC_BITS(2),
        .OUT_WIDTH(9),
        .OUT_MAX(200),
        .OUT_MIN(-40)
    ) DUT_OTHER (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .reference(other_reference),
        .measured(other_measured),
        .kp(other_kp),
        .error(other_error),
        .p_action(other_action)
    );

    p_controller #(
        .IN_WIDTH(16),
        .KP_WIDTH(4),
        .OUT_WIDTH(9),
        .OUT_MAX(255),
        .OUT_MIN(-255)
    ) DUT_SAME (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .reference(disk_reference),
        .measured(disk_measured),
        .kp(disk_kp),
        .error(same_error),
        .p_action(same_action)
    );

    always #5 clk = ~clk;   // 100 MHz

    //--------------------------------------------------------------------------
    // Helpers
    //--------------------------------------------------------------------------
    task automatic expect_value(int actual, int expected, string what);
        checks++;
        if (actual != expected) begin
            errors++;
            $display("FAIL %s: got %0d, expected %0d", what, actual, expected);
        end
    endtask

    // Apply the inputs, give one sample_tick, then the new outputs can be read.
    task automatic sample_disk(int reference, int measured, int gain);
        @(negedge clk);
        disk_reference = 16'(reference);
        disk_measured  = 16'(measured);
        disk_kp        = 4'(gain);
        sample_tick    = 1;
        @(negedge clk);
        sample_tick    = 0;
    endtask

    task automatic sample_other(int reference, int measured, int gain);
        @(negedge clk);
        other_reference = 12'(reference);
        other_measured  = 12'(measured);
        other_kp        = 4'(gain);
        sample_tick     = 1;
        @(negedge clk);
        sample_tick     = 0;
    endtask

    task automatic check_disk(int reference, int measured, int gain, int expected, string what);
        sample_disk(reference, measured, gain);
        expect_value(disk_action, expected, {"disk, ", what});
    endtask

    //--------------------------------------------------------------------------
    // Test sequence
    //--------------------------------------------------------------------------
    initial begin
        repeat (2) @(negedge clk);
        reset = 0;

        // 1. The disk, as disk_top uses it.
        //          reference measured  Kp  expected
        check_disk(      100,       0,   1,     100, "Kp 1, positive error");
        check_disk(        0,     100,   1,    -100, "Kp 1, negative error");
        check_disk(       10,       0,   2,      20, "Kp 2");
        check_disk(        0,      40,   3,    -120, "Kp 3, reverse");
        check_disk(      100,      97,   2,       6, "small error");
        check_disk(      100,       0,   3,     255, "limited at +255");
        check_disk(     -100,       0,   3,    -255, "limited at -255");
        check_disk(    32767,  -32768,  15,     255, "largest positive error");
        check_disk(   -32768,   32767,  15,    -255, "largest negative error");
        check_disk(      500,     500,  15,       0, "zero error");
        check_disk(      500,       0,   0,       0, "zero gain");

        // 2. The error output and its sign: reference - measured, full width.
        sample_disk(10, 4, 1);
        expect_value(disk_error, 6, "error = reference - measured (10 - 4)");
        sample_disk(32767, -32768, 1);
        expect_value(disk_error, 65535, "error at full width (32,767 - (-32,768))");

        // 3. The limits are parameters of each instance, not constants in the
        //    module: the same inputs that DUT_DISK limits come out unlimited
        //    from DUT_FREE.
        sample_disk(100, 0, 3);
        expect_value(disk_action, 255, "disk instance limits 300 to 255");
        expect_value(free_action, 300, "default instance does not limit 300");

        // 4. Full-width product: 65,535 x 15 = 983,025 needs 21 bits plus a
        //    sign. A shorter product wraps around and changes sign.
        sample_disk(32767, -32768, 15);
        expect_value(free_action, 983025, "largest positive product, exact");
        sample_disk(-32768, 32767, 15);
        expect_value(free_action, -983025, "largest negative product, exact");

        // 5. Another plant: limits -40 ... +200 and gain kp / 4.
        sample_other(1000, 0, 4);                      // 4000 / 4 = 1000
        expect_value(other_action, 200, "other plant, limited at +200");
        sample_other(0, 100, 4);                       // -400 / 4 = -100
        expect_value(other_action, -40, "other plant, limited at -40");
        sample_other(7, 0, 3);                         // 21 / 4 = 5.25
        expect_value(other_action, 5, "other plant, 21 / 4 rounds down to 5");
        sample_other(0, 7, 3);                         // -21 / 4 = -5.25
        expect_value(other_action, -6, "other plant, -21 / 4 rounds down to -6");
        sample_other(-2048, 2047, 1);                  // largest negative error
        expect_value(other_error, -4095, "other plant, error at full width");

        // 6. Without a sample_tick, p_action holds.
        check_disk(40, 0, 1, 40, "load 40");
        @(negedge clk);
        disk_reference = 16'sd200;
        repeat (3) @(negedge clk);
        expect_value(disk_action, 40, "disk, holds without a sample_tick");

        // 7. Reset clears p_action (DUT_SAME was loaded with 40 alongside DUT_DISK).
        expect_value(same_action, 40, "second disk copy loaded");
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        reset = 0;
        expect_value(same_action, 0, "reset clears p_action");

        if (errors == 0) $display("PASS tb_p_controller (%0d checks)", checks);
        else             $display("FAIL tb_p_controller: %0d of %0d checks failed", errors, checks);
        $finish;
    end

endmodule
