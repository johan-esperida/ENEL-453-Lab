`timescale 1ns / 1ps
//==============================================================================
// Module: motor_drive
//
// Purpose
//   Converts the controller's signed command into the three signals the L298N
//   H-bridge motor driver needs:
//
//     motor_in1, motor_in2 : direction (wired to the L298N's IN3 and IN4)
//     motor_en             : PWM power (wired to the L298N's ENB)
//
//   The sign of the command picks the direction; its size (magnitude) sets
//   the PWM duty cycle. This is "coast mode": while the PWM is off, the motor
//   is disconnected and spins freely. ENEL 441 and ENCM 511 drive the same
//   motor the same way.
//
//   L298N truth table (one motor channel):
//
//     motor_en  motor_in1  motor_in2   motor
//     --------  ---------  ---------   -------------------------------
//        0          x          x       coasts (driver off)
//        1          1          0       forward (position count rises)
//        1          0          1       reverse (position count falls)
//        1          0          0       brakes (never used here: EN is
//                                      0 whenever both IN are 0)
//
//   Examples:
//     command = +200 -> in1 = 1, in2 = 0, duty = 200 (78%), forward
//     command =  -64 -> in1 = 0, in2 = 1, duty =  64 (25%), reverse
//     command =    0 -> in1 = 0, in2 = 0, duty =   0,       off
//
//   If the motor turns the wrong way (the disk runs away instead of holding),
//   swap the two motor wires on the L298N outputs; no code change is needed.
//
// Safety
//   arm = 0 forces all three outputs to 0 (motor off), whatever the command.
//   arm comes from a slide switch, so the motor can be stopped at any time.
//
// Block diagram
//
//                       duty       +---------+
//   command --+--->[ |x| ]-------->|  pwm    |--------------------> motor_en
//             |                    |         |
//             |    pwm_tick ------>|         |
//             |    arm ----------->| enable  |
//             |                    +---------+
//             |
//             +--->[ > 0 ? ]--[AND arm]--[register]---------------> motor_in1
//             +--->[ < 0 ? ]--[AND arm]--[register]---------------> motor_in2
//
// Constants (from disk_pkg)
//   COMMAND_WIDTH = 9 (signed command), DUTY_WIDTH = 8 (PWM duty cycle)
//
// Inputs
//   clk       : 100 MHz system clock
//   reset     : synchronous, active-high reset. Turns the motor off.
//   arm       : 1 = motor allowed to run, 0 = motor off
//   pwm_tick  : clock-enable pulses that set the PWM frequency (see pwm.sv)
//   command   : signed motor command, -255 to +255
//
// Outputs
//   motor_en  : PWM signal to the L298N enable input (ENB)
//   motor_in1 : direction signal to the L298N (IN3): 1 = forward
//   motor_in2 : direction signal to the L298N (IN4): 1 = reverse
//
// Internal signals
//   duty : magnitude (absolute value) of the command, 0 to 255, used as the
//          8-bit PWM duty cycle
//==============================================================================

module motor_drive
    import disk_pkg::*;               // COMMAND_WIDTH, DUTY_WIDTH
(
    input  logic                            clk,
    input  logic                            reset,
    input  logic                            arm,
    input  logic                            pwm_tick,
    input  logic signed [COMMAND_WIDTH-1:0] command,
    output logic                            motor_en,
    output logic                            motor_in1,
    output logic                            motor_in2
);

    logic [DUTY_WIDTH-1:0] duty;

    // Magnitude (absolute value) of the command, used as the PWM duty cycle.
    // The command is limited to -255 ... +255, so its magnitude, 0 to 255,
    // always fits in DUTY_WIDTH = 8 bits; the DUTY_WIDTH'( ) cast keeps just
    // those 8 bits.
    assign duty = (command < 0) ? DUTY_WIDTH'(-command) : DUTY_WIDTH'(command);

    // PWM for the motor power. While arm = 0 the PWM output is held off.
    pwm #(
        .WIDTH(DUTY_WIDTH)          // 8-bit duty cycle
    ) MOTOR_PWM (
        .clk(clk),                  // system clock
        .reset(reset),              // synchronous reset
        .enable(arm),               // motor armed by the slide switch
        .count_enable(pwm_tick),    // sets the PWM frequency (about 10 kHz)
        .duty_cycle(duty),          // 0 = off ... 255 = full power
        .pwm_out(motor_en)          // to the L298N enable input
    );

    // Direction signals, registered like motor_en so all three outputs
    // change on the same clock edge.
    always_ff @(posedge clk) begin
        if (reset) begin
            motor_in1 <= 1'b0;
            motor_in2 <= 1'b0;
        end else begin
            motor_in1 <= arm && (command > 0);
            motor_in2 <= arm && (command < 0);
        end
    end

endmodule
