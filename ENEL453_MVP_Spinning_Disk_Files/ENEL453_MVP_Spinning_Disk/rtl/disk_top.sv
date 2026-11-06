`timescale 1ns / 1ps
//==============================================================================
// Module: disk_top  (top level)
//
// Purpose
//   Position control of a rotating disk with the Basys3. A DC motor turns the
//   disk; a quadrature encoder on the shaft measures its angle. The FPGA runs
//   a proportional (P) controller that drives the motor, through an L298N
//   H-bridge, until the disk sits at the commanded angle (the setpoint).
//
//   This file only connects modules together (it is "structural"): all the
//   logic lives in the modules it instantiates.
//
// What the user sees and does
//   btnC (reset_button)      : reset. Position and setpoint both become 0,
//                              so the disk holds wherever it is now.
//   btnR (step_up_button)    : move the setpoint +90 degrees
//   btnL (step_down_button)  : move the setpoint -90 degrees
//   sw[3:0] (kp_switches)    : proportional gain Kp, 0 to 15 (try 2 first)
//   sw[15] (arm_switch)      : up = motor allowed to run, down = motor off
//   7-segment display        : disk angle within one revolution, " 000"-" 359"
//   led[3:0]                 : Kp
//   led[8], led[9]           : encoder channels A and B (flicker when turning)
//   led[14], led[13]         : motor direction, forward / reverse
//   led[15]                  : motor armed
//
// Block diagram
//
//                 +--------------+  encoder_a,b  +--------------+  position
//   ch_a, ch_b -->| synchronizer |-------------->| quad_decoder |-----------+
//                 +--------------+               +--------------+           |
//                                                                           v
//                 +----------+  step_up,  +------------------+  setpoint  +--------------+
//   btnR, btnL -->| debounce |----------->| setpoint_control |----------->|              |
//                 |   (x2)   | step_down  +------------------+            | p_controller |
//                 +----------+                                            |              |
//                 +--------------+  kp                                    |  command =   |
//   sw[3:0] ----->| synchronizer |--------------------------------------->| Kp x error   |
//                 +--------------+                                        +--------------+
//                 +-------------+ control_tick (100 Hz) ------------------------^    |
//                 | downcounter |                                                    | command
//                 +-------------+                                                    v
//                 +--------------+  arm                                   +-------------+
//   sw[15] ------>| synchronizer |--------------------------------------->|             |--> motor_en
//                 +--------------+                                        | motor_drive |--> motor_in1
//                 +-------------+ pwm_tick (2.56 MHz -> 10 kHz PWM) ----->|             |--> motor_in2
//                 | downcounter |                                         +-------------+
//                 +-------------+
//
//   position --> position_to_degrees --> bin_to_bcd --> seven_segment_display_subsystem
//                    (0-359 degrees)     (BCD digits)    --> CA..CG, DP, AN1..AN4
//
//   btnC --> synchronizer --> reset (to every module that has a reset)
//
// Clocking and reset
//   Every flip-flop runs on the one 100 MHz clock, clk. Slower actions (the
//   100 Hz controller, the 10 kHz PWM) use one-cycle clock-enable pulses from
//   downcounter modules, never a second clock.
//   reset is synchronous and active high everywhere. It comes from btnC
//   through a synchronizer, so it changes in step with the clock.
//
// Signal flow, step by step
//   1. The encoder channels are synchronized, then decoded into "position"
//      (2048 counts per revolution; 1 count is about 0.18 degrees).
//   2. The step buttons are debounced; each press moves "setpoint" by
//      +/-512 counts (90 degrees).
//   3. 100 times per second, p_controller computes
//          command = Kp x (setpoint - position), limited to +/-255.
//   4. motor_drive turns the command into a direction (motor_in1/in2) and a
//      10 kHz PWM duty cycle (motor_en) for the L298N.
//   5. The display shows the angle: position -> degrees -> BCD digits.
//
// Parameters (defaults come from disk_pkg; the closed-loop testbench
// overrides them with a slower clock so that simulation runs quickly)
//   CLK_FREQ    : system clock frequency, Hz        (CLK_FREQ_HZ      = 100 MHz)
//   CTRL_FREQ   : controller sample rate, Hz        (CONTROL_FREQ_HZ  = 100 Hz)
//   PWM_FREQ    : motor PWM frequency, Hz, approx.  (PWM_FREQ_HZ      = 10 kHz)
//   DEBOUNCE_MS : push-button debounce time, ms     (DEBOUNCE_TIME_MS = 50 ms)
//
// Constants (from disk_pkg)
//   POSITION_WIDTH = 16, KP_WIDTH = 4, COMMAND_WIDTH = 9, DEGREES_WIDTH = 9,
//   COMMAND_MAX = 255 (also the number of PWM steps in one period)
//
// Inputs
//   clk              : 100 MHz clock from the Basys3 oscillator (pin W5)
//   reset_button     : btnC, 1 while pressed
//   step_up_button   : btnR, 1 while pressed
//   step_down_button : btnL, 1 while pressed
//   kp_switches      : sw[3:0], the gain Kp
//   arm_switch       : sw[15], 1 = motor allowed to run
//   ch_a, ch_b       : encoder channels A and B (Pmod JB1, JB2)
//
// Outputs
//   motor_en         : PWM to the L298N ENB input (Pmod JC3)
//   motor_in1        : direction to the L298N IN3 input (Pmod JC1)
//   motor_in2        : direction to the L298N IN4 input (Pmod JC2)
//   led              : the 16 LEDs above the switches
//   CA..CG, DP       : 7-segment segment outputs (active low)
//   AN1..AN4         : 7-segment anode outputs (active low, AN1 = rightmost)
//
// Internal signals
//   reset        : synchronized reset, active high
//   encoder_a,b  : synchronized encoder channels
//   kp           : synchronized gain switches, 0 to 15
//   arm          : synchronized arm switch
//   step_up      : debounced btnR level
//   step_down    : debounced btnL level
//   control_tick : 100 Hz clock-enable pulse for the controller
//   pwm_tick     : clock-enable pulse that steps the PWM counter
//   position     : measured disk position, counts (signed)
//   setpoint     : desired disk position, counts (signed)
//   command      : motor command, -255 to +255
//   degrees      : disk angle within one revolution, 0 to 359
//   degrees_bcd  : the angle as four BCD digits, for the display
//==============================================================================

module disk_top
    import disk_pkg::*;                             // shared constants and widths
#(
    parameter int CLK_FREQ    = CLK_FREQ_HZ,        // 100 MHz
    parameter int CTRL_FREQ   = CONTROL_FREQ_HZ,    // 100 Hz
    parameter int PWM_FREQ    = PWM_FREQ_HZ,        // 10 kHz
    parameter int DEBOUNCE_MS = DEBOUNCE_TIME_MS    // 50 ms
) (
    input  logic                 clk,
    input  logic                 reset_button,
    input  logic                 step_up_button,
    input  logic                 step_down_button,
    input  logic [KP_WIDTH-1:0]  kp_switches,
    input  logic                 arm_switch,
    input  logic                 ch_a,
    input  logic                 ch_b,
    output logic                 motor_en,
    output logic                 motor_in1,
    output logic                 motor_in2,
    output logic [15:0]          led,
    output logic                 CA, CB, CC, CD, CE, CF, CG,
    output logic                 DP,
    output logic                 AN1, AN2, AN3, AN4
);

    // Clock cycles between controller samples: 100,000,000 / 100 = 1,000,000.
    localparam int CTRL_PERIOD     = CLK_FREQ / CTRL_FREQ;
    // Clock cycles between PWM counter steps. One PWM period is COMMAND_MAX =
    // 255 steps, so 100,000,000 / (10,000 x 255) = 39.2 -> 39, giving 10.06 kHz.
    localparam int PWM_TICK_PERIOD = CLK_FREQ / (PWM_FREQ * COMMAND_MAX);

    logic                             reset;
    logic                             encoder_a;
    logic                             encoder_b;
    logic        [KP_WIDTH-1:0]       kp;
    logic                             arm;
    logic                             step_up;
    logic                             step_down;
    logic                             control_tick;
    logic                             pwm_tick;
    logic signed [POSITION_WIDTH-1:0] position;
    logic signed [POSITION_WIDTH-1:0] setpoint;
    logic signed [COMMAND_WIDTH-1:0]  command;
    logic        [DEGREES_WIDTH-1:0]  degrees;
    logic        [15:0]               degrees_bcd;

    //--------------------------------------------------------------------------
    // Inputs: synchronize the switches, encoder and reset button; debounce the
    // step buttons.
    //--------------------------------------------------------------------------

    // Reset button. The synchronizer has no reset of its own, so it can
    // synchronize the reset button itself.
    synchronizer #(
        .WIDTH(1)
    ) RESET_SYNC (
        .clk(clk),                    // system clock
        .d(reset_button),             // btnC, asynchronous
        .q(reset)                     // synchronized reset for the whole design
    );

    // Encoder channel A.
    synchronizer #(
        .WIDTH(1)
    ) ENCODER_A_SYNC (
        .clk(clk),                    // system clock
        .d(ch_a),                     // encoder channel A, from Pmod JB1
        .q(encoder_a)                 // synchronized channel A
    );

    // Encoder channel B.
    synchronizer #(
        .WIDTH(1)
    ) ENCODER_B_SYNC (
        .clk(clk),                    // system clock
        .d(ch_b),                     // encoder channel B, from Pmod JB2
        .q(encoder_b)                 // synchronized channel B
    );

    // Gain switches, all four bits in one synchronizer.
    synchronizer #(
        .WIDTH(KP_WIDTH)               // 4 switches
    ) KP_SYNC (
        .clk(clk),                    // system clock
        .d(kp_switches),              // sw[3:0]
        .q(kp)                        // synchronized gain, 0 to 15
    );

    // Arm switch.
    synchronizer #(
        .WIDTH(1)
    ) ARM_SYNC (
        .clk(clk),                    // system clock
        .d(arm_switch),               // sw[15]
        .q(arm)                       // synchronized: 1 = motor allowed to run
    );

    // Step-up button (btnR).
    debounce #(
        .CLK_FREQ(CLK_FREQ),          // system clock frequency, Hz
        .STABLE_TIME_MS(DEBOUNCE_MS)  // button must be steady this long
    ) STEP_UP_DEBOUNCE (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .button(step_up_button),      // raw btnR
        .result(step_up)              // debounced: 1 while held
    );

    // Step-down button (btnL).
    debounce #(
        .CLK_FREQ(CLK_FREQ),          // system clock frequency, Hz
        .STABLE_TIME_MS(DEBOUNCE_MS)  // button must be steady this long
    ) STEP_DOWN_DEBOUNCE (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .button(step_down_button),    // raw btnL
        .result(step_down)            // debounced: 1 while held
    );

    //--------------------------------------------------------------------------
    // Clock-enable pulses
    //--------------------------------------------------------------------------

    // 100 Hz pulse: tells the controller when to take a sample.
    downcounter #(
        .PERIOD(CTRL_PERIOD)          // 1,000,000 cycles = 10 ms
    ) CONTROL_TICK_GEN (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .enable(1'b1),                // always counting
        .zero(control_tick)           // one-cycle pulse every 10 ms
    );

    // 2.56 MHz pulse: steps the PWM counter (255 steps = one 10 kHz period).
    downcounter #(
        .PERIOD(PWM_TICK_PERIOD)      // 39 cycles = 390 ns
    ) PWM_TICK_GEN (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .enable(1'b1),                // always counting
        .zero(pwm_tick)               // one-cycle pulse every 39 cycles
    );

    //--------------------------------------------------------------------------
    // The control loop: measure, compare, drive
    //--------------------------------------------------------------------------

    // Measure: encoder channels -> position in counts.
    quad_decoder QUAD_DECODER (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: position = 0
        .a(encoder_a),                // synchronized channel A
        .b(encoder_b),                // synchronized channel B
        .position(position)           // signed position, counts
    );

    // Setpoint: +/-90 degrees per button press.
    setpoint_control SETPOINT_CONTROL (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: setpoint = 0
        .step_up(step_up),            // debounced btnR
        .step_down(step_down),        // debounced btnL
        .setpoint(setpoint)           // desired position, counts
    );

    // Compare: command = Kp x (setpoint - position), limited to +/-255.
    // p_controller knows nothing about the disk (it is written to be reused
    // unchanged, for example inside a PI controller), so the disk's sizes and
    // limits are given to it here, as parameters.
    p_controller #(
        .IN_WIDTH(POSITION_WIDTH),    // setpoint and position: 16 bits
        .KP_WIDTH(KP_WIDTH),          // kp: 4 bits, 0 to 15
        .FRAC_BITS(0),                // Kp is a whole number
        .OUT_WIDTH(COMMAND_WIDTH),    // command: 9 bits
        .OUT_MAX(COMMAND_MAX),        // +255: full power forward
        .OUT_MIN(-COMMAND_MAX)        // -255: full power reverse
    ) P_CONTROLLER (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: command = 0
        .sample_tick(control_tick),   // update 100 times per second
        .reference(setpoint),         // desired position, counts
        .measured(position),          // measured position, counts
        .kp(kp),                      // gain from sw[3:0]
        .error(),                     // setpoint - position: not needed here
        .p_action(command)            // -255 (full reverse) to +255 (full forward)
    );

    // Drive: command -> L298N direction and PWM signals.
    motor_drive MOTOR_DRIVE (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: motor off
        .arm(arm),                    // sw[15]: 0 forces the motor off
        .pwm_tick(pwm_tick),          // sets the PWM frequency
        .command(command),            // signed motor command
        .motor_en(motor_en),          // to L298N ENB (PWM)
        .motor_in1(motor_in1),        // to L298N IN3 (forward)
        .motor_in2(motor_in2)         // to L298N IN4 (reverse)
    );

    //--------------------------------------------------------------------------
    // Display: position -> degrees -> BCD digits -> 7-segment display
    //--------------------------------------------------------------------------

    position_to_degrees POSITION_TO_DEGREES (
        .position(position),          // signed position, counts
        .degrees(degrees)             // angle within one revolution, 0 to 359
    );

    bin_to_bcd BIN_TO_BCD (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .bin_in(16'(degrees)),        // 9-bit angle, zero-extended to 16 bits
        .bcd_out(degrees_bcd)         // four BCD digits, e.g. 0359
    );

    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .digit1(degrees_bcd[3:0]),    // ones of degrees (rightmost digit)
        .digit2(degrees_bcd[7:4]),    // tens of degrees
        .digit3(degrees_bcd[11:8]),   // hundreds of degrees
        .digit4(degrees_bcd[15:12]),  // thousands: always 0, blanked (leftmost)
        .decimal_point(4'b0000),      // no decimal points
        .digit_blank(4'b1000),        // leftmost digit dark: shows " 090"
        .CA(CA),                      // segment outputs (active low)
        .CB(CB),
        .CC(CC),
        .CD(CD),
        .CE(CE),
        .CF(CF),
        .CG(CG),
        .DP(DP),                      // decimal point output (active low)
        .AN1(AN1),                    // anode outputs (active low)
        .AN2(AN2),
        .AN3(AN3),
        .AN4(AN4)
    );

    //--------------------------------------------------------------------------
    // LEDs: status at a glance
    //--------------------------------------------------------------------------
    assign led[3:0]   = kp;           // gain Kp, in binary
    assign led[7:4]   = 4'b0000;      // unused
    assign led[8]     = encoder_a;    // encoder channel A (flickers when turning)
    assign led[9]     = encoder_b;    // encoder channel B (flickers when turning)
    assign led[12:10] = 3'b000;       // unused
    assign led[13]    = motor_in2;    // motor driving in reverse
    assign led[14]    = motor_in1;    // motor driving forward
    assign led[15]    = arm;          // motor armed

endmodule
