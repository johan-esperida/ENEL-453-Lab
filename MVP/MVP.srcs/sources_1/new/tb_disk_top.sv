`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_disk_top  (closed loop)
//
// Tests the whole design with a simple model of the motor, disk and encoder
// closing the loop:
//
//   disk_top --(motor_en, motor_in1, motor_in2)--> motor + disk model
//      ^                                                  |
//      +------------------(ch_a, ch_b)--------------------+
//
// Plant model (one update per clock cycle):
//   drive  : +1 forward, -1 reverse, 0 off, from the three motor signals,
//            smoothed over 2 ms (the motor winding averages the PWM pulses)
//   delay  : the drive acts after 15 ms (current build-up, gearbox backlash)
//   push   : drive minus a friction dead band (6% drive to start moving)
//   speed  : first-order response, time constant 10 ms, 1.3 rev/s at full
//            drive, plus sliding friction that slows a moving disk
//   angle  : integral of speed, in counts; ch_a/ch_b follow from the angle
// The parameters are fitted to the real rig: oscillation for Kp >= 7 with a
// period of about 0.12 s, no overshoot at Kp = 2, about 4 deg at Kp = 4.
//
// The clock is scaled down to 1 MHz (the debounce time to 5 ms and the PWM to
// 1 kHz), so that seconds of disk motion simulate quickly.
//
// Sequence and checks:
//   1. after reset: setpoint 0, disk holds at 0
//   2. btnR: setpoint +512 (+90 deg); the disk settles within +/-8 counts,
//      with no more than 20 counts (3.5 deg) of overshoot at Kp = 2
//   3. btnL twice: setpoint -512 (-90 deg = 270 deg on the display)
//   4. the display digits match the disk angle; the Kp LEDs show Kp
//   5. disarmed (sw[15] down): the motor outputs stay off even with an error
//   6. the leftmost display digit is blanked: AN4 never turns on
//      (when you add the counts display, which lights all four digits, this
//      check must apply in degrees mode only: see the monitor below)
// Prints PASS or FAIL.
//==============================================================================

module tb_disk_top;

    import disk_pkg::*;    // COUNTS_PER_REV, POSITION_WIDTH, KP_WIDTH

    localparam int  CLK_FREQ       = 1_000_000;   // scaled-down clock for a fast simulation
    localparam real DT             = 1.0 / CLK_FREQ;   // seconds per clock cycle
    // Plant parameters, fitted to bench measurements of a real rig: the loop
    // oscillates for Kp >= 7 with a period of about 0.12 s, a +90 deg step has
    // no overshoot at Kp = 2 and about 4 deg at Kp = 4.
    localparam real SPEED_MAX        = 2700.0;  // counts/s at full drive (1.3 rev/s)
    localparam real TAU              = 0.010;   // speed time constant, s
    localparam real FRICTION         = 0.06;    // drive needed to start moving (6%)
    localparam real SLIDING_FRICTION = 20000.0; // deceleration of a moving disk, counts/s^2
    localparam real DELAY            = 0.015;   // actuator delay, s
    localparam real PWM_SMOOTHING    = 0.002;   // the winding averages the PWM, s
    localparam int  DELAY_CYCLES     = $rtoi(DELAY * CLK_FREQ);
    localparam int  TOLERANCE        = 8;       // allowed steady-state error, counts
    localparam int  KP             = 2;

    logic                clk              = 0;
    logic                reset_button     = 1;
    logic                step_up_button   = 0;
    logic                step_down_button = 0;
    logic [KP_WIDTH-1:0] kp_switches      = KP_WIDTH'(KP);
    logic                arm_switch       = 1;
    logic                ch_a, ch_b;
    logic                motor_en, motor_in1, motor_in2;
    logic [15:0]         led;
    logic                CA, CB, CC, CD, CE, CF, CG, DP;
    logic                AN1, AN2, AN3, AN4;
    int                  errors           = 0;

    disk_top #(
        .CLK_FREQ(CLK_FREQ),
        .CTRL_FREQ(100),
        .PWM_FREQ(1_000),
        .DEBOUNCE_MS(5)
    ) DUT (
        .clk(clk),
        .reset_button(reset_button),
        .step_up_button(step_up_button),
        .step_down_button(step_down_button),
        .kp_switches(kp_switches),
        .arm_switch(arm_switch),
        .ch_a(ch_a),
        .ch_b(ch_b),
        .motor_en(motor_en),
        .motor_in1(motor_in1),
        .motor_in2(motor_in2),
        .led(led),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
        .DP(DP),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4)
    );

    always #500 clk = ~clk;   // 1 MHz

    //--------------------------------------------------------------------------
    // Plant: motor signals -> averaged drive -> speed -> angle -> ch_a, ch_b
    //--------------------------------------------------------------------------
    localparam logic [1:0] SEQUENCE [4] = '{2'b00, 2'b10, 2'b11, 2'b01};

    real drive;
    real drive_average = 0.0;
    real drive_delayed;
    real push;
    real speed         = 0.0;
    real angle         = 0.0;
    real slow_down;
    real delay_line [DELAY_CYCLES];       // the actuator delay, one entry per clock cycle
    int  delay_index   = 0;
    int  count;

    initial foreach (delay_line[i]) delay_line[i] = 0.0;

    always @(posedge clk) begin
        // Motor voltage as a fraction of full drive: +1 forward, -1 reverse, 0 off.
        drive          = !motor_en ? 0.0 : motor_in1 ? 1.0 : motor_in2 ? -1.0 : 0.0;
        // The winding smooths the PWM pulses into an average drive.
        drive_average += (drive - drive_average) * DT / PWM_SMOOTHING;
        // ... and the drive acts on the disk only after a delay (current build-up,
        // gearbox backlash): a delay line DELAY_CYCLES long.
        drive_delayed            = delay_line[delay_index];
        delay_line[delay_index]  = drive_average;
        delay_index              = (delay_index + 1) % DELAY_CYCLES;
        // Static friction: a drive smaller than FRICTION cannot start the disk.
        push           = (drive_delayed >  FRICTION) ? drive_delayed - FRICTION :
                         (drive_delayed < -FRICTION) ? drive_delayed + FRICTION : 0.0;
        // Speed follows the drive with time constant TAU ...
        speed         += (SPEED_MAX * push - speed) * DT / TAU;
        // ... and sliding friction slows a moving disk, but never reverses it.
        slow_down      = SLIDING_FRICTION * DT;
        speed          = (speed >  slow_down) ? speed - slow_down :
                         (speed < -slow_down) ? speed + slow_down : 0.0;
        angle         += speed * DT;
    end

    assign count        = $rtoi($floor(angle));
    assign {ch_a, ch_b} = SEQUENCE[((count % 4) + 4) % 4];

    //--------------------------------------------------------------------------
    // Helpers
    //--------------------------------------------------------------------------
    task automatic wait_seconds(real seconds);
        repeat ($rtoi(seconds * CLK_FREQ)) @(posedge clk);
    endtask

    task automatic press_up();
        step_up_button = 1;   wait_seconds(0.03);
        step_up_button = 0;   wait_seconds(0.03);
    endtask

    task automatic press_down();
        step_down_button = 1; wait_seconds(0.03);
        step_down_button = 0; wait_seconds(0.03);
    endtask

    task automatic check_settled(int target, string what);
        int position, degrees, shown;
        position = DUT.position;
        degrees  = ((position % COUNTS_PER_REV + COUNTS_PER_REV) % COUNTS_PER_REV)
                   * 360 / COUNTS_PER_REV;
        shown    = DUT.degrees_bcd[11:8] * 100 + DUT.degrees_bcd[7:4] * 10
                 + DUT.degrees_bcd[3:0];
        if (DUT.setpoint !== POSITION_WIDTH'(target)) begin
            errors++;
            $display("FAIL %s: setpoint = %0d, expected %0d", what, DUT.setpoint, target);
        end
        if (position < target - TOLERANCE || position > target + TOLERANCE) begin
            errors++;
            $display("FAIL %s: position = %0d, expected %0d +/- %0d",
                     what, position, target, TOLERANCE);
        end
        if (shown != degrees) begin
            errors++;
            $display("FAIL %s: display shows %0d, expected %0d degrees", what, shown, degrees);
        end
        $display("%-16s setpoint %5d  position %5d  display %04h deg",
                 what, target, position, DUT.degrees_bcd);
    endtask

    //--------------------------------------------------------------------------
    // Overshoot: the largest position reached after the +90 deg step.
    localparam int MAX_OVERSHOOT = 20;    // counts (3.5 deg)
    int peak_position = 0;

    always @(posedge clk)
        if (DUT.position > peak_position) peak_position = DUT.position;

    //--------------------------------------------------------------------------
    // Display blanking: the leftmost digit (AN4, active low) must never turn on.
    // This is true of the degrees display only. When you add the counts
    // display (sw[10] up lights all four digits), add your switch to the
    // condition below, so that the check only runs in degrees mode.
    //--------------------------------------------------------------------------
    int an4_errors = 0;

    always @(posedge clk)
        if (!reset_button && AN4 === 1'b0 && an4_errors == 0) begin
            an4_errors++;
            $display("FAIL blanking: AN4 turned on at %t", $time);
        end

    //--------------------------------------------------------------------------
    // Test sequence
    //--------------------------------------------------------------------------
    initial begin
        wait_seconds(0.001);
        reset_button = 0;
        wait_seconds(0.1);
        check_settled(0, "after reset");

        if (led[3:0] !== KP_WIDTH'(KP) || led[15] !== 1'b1) begin
            errors++;
            $display("FAIL LEDs: Kp = %b, armed = %b", led[3:0], led[15]);
        end

        peak_position = 0;
        press_up();
        wait_seconds(1.5);
        check_settled(COUNTS_PER_REV / 4, "+90 deg");
        // The real rig shows no overshoot at Kp = 2; allow up to 20 counts (3.5 deg).
        $display("%-16s overshoot %0d counts", "+90 deg step", peak_position - COUNTS_PER_REV / 4);
        if (peak_position - COUNTS_PER_REV / 4 > MAX_OVERSHOOT) begin
            errors++;
            $display("FAIL +90 deg: overshoot %0d counts, more than %0d",
                     peak_position - COUNTS_PER_REV / 4, MAX_OVERSHOOT);
        end

        press_down();
        press_down();
        wait_seconds(1.5);
        check_settled(-(COUNTS_PER_REV / 4), "-90 deg");

        // Disarmed: the motor must stay off even with a large error.
        arm_switch = 0;
        press_up();
        press_up();
        fork
            begin : watch
                forever @(posedge clk)
                    if (motor_en || motor_in1 || motor_in2) begin
                        errors++;
                        $display("FAIL disarmed: motor driven at %t", $time);
                        disable watch;
                    end
            end
            wait_seconds(0.5);
        join_any
        disable fork;

        errors += an4_errors;
        if (errors == 0) $display("PASS tb_disk_top");
        else             $display("FAIL tb_disk_top: %0d errors", errors);
        $finish;
    end

endmodule
