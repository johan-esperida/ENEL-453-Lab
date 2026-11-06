`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_motor_drive
//
// For several commands, measures the PWM duty cycle on motor_en (by counting
// "on" clock cycles over whole PWM periods) and checks the direction pins:
//   - +200 -> forward, 200/255 on
//   -  -64 -> reverse,  64/255 on
//   -    0 -> off
//   - +255 / -255 -> always on, forward / reverse
//   - arm = 0 -> all outputs off, whatever the command
// pwm_tick is held at 1, so one PWM period is exactly 255 clock cycles.
// Prints PASS or FAIL.
//==============================================================================

module tb_motor_drive;

    import disk_pkg::*;    // COMMAND_WIDTH, COMMAND_MAX

    localparam int PERIOD  = COMMAND_MAX;   // clock cycles per PWM period: 255
    localparam int PERIODS = 4;     // periods measured per check

    logic                            clk      = 0;
    logic                            reset    = 1;
    logic                            arm      = 1;
    logic                            pwm_tick = 1;
    logic signed [COMMAND_WIDTH-1:0] command  = '0;
    logic                            motor_en;
    logic                            motor_in1;
    logic                            motor_in2;
    int                              errors   = 0;

    motor_drive DUT (
        .clk(clk),
        .reset(reset),
        .arm(arm),
        .pwm_tick(pwm_tick),
        .command(command),
        .motor_en(motor_en),
        .motor_in1(motor_in1),
        .motor_in2(motor_in2)
    );

    always #5 clk = ~clk;   // 100 MHz

    task automatic check(int cmd, logic armed, int on_per_period,
                         logic in1, logic in2, string what);
        int on_cycles = 0;
        @(negedge clk);
        command = COMMAND_WIDTH'(cmd);
        arm     = armed;
        repeat (PERIOD) @(negedge clk);              // let one period pass
        repeat (PERIODS * PERIOD) begin
            @(negedge clk);
            if (motor_en) on_cycles++;
            if (motor_in1 !== in1 || motor_in2 !== in2) begin
                errors++;
                $display("FAIL %s: in1, in2 = %b%b, expected %b%b",
                         what, motor_in1, motor_in2, in1, in2);
                break;
            end
        end
        if (on_cycles != PERIODS * on_per_period) begin
            errors++;
            $display("FAIL %s: on for %0d of %0d cycles, expected %0d",
                     what, on_cycles, PERIODS * PERIOD, PERIODS * on_per_period);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        reset = 0;

        //     command  arm  on/period  in1  in2
        check(   200,   1,     200,     1,   0, "+200 forward");
        check(   -64,   1,      64,     0,   1, "-64 reverse");
        check(     0,   1,       0,     0,   0, "zero command");
        check(   255,   1,     255,     1,   0, "+255 full forward");
        check(  -255,   1,     255,     0,   1, "-255 full reverse");
        check(   200,   0,       0,     0,   0, "disarmed");

        if (errors == 0) $display("PASS tb_motor_drive");
        else             $display("FAIL tb_motor_drive: %0d errors", errors);
        $finish;
    end

endmodule
