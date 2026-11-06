`timescale 1ns / 1ps
//==============================================================================
// Module: p_controller
//
// Purpose
//   Proportional (P) controller. Once per sample it measures how far the
//   plant is from where it should be, and commands the actuator in proportion
//   to that distance:
//
//       error    = reference - measured
//       p_action = (Kp x error) >>> FRAC_BITS, limited to OUT_MIN ... OUT_MAX
//
//   In this project the plant is the rotating disk: reference is the
//   setpoint, measured is the encoder position (both in encoder counts),
//   FRAC_BITS = 0 (Kp is a whole number), and the limits are -255 ... +255,
//   so p_action is the motor command. The sign of the command is the
//   direction; its size is the PWM duty cycle (255 = full power). A large
//   error gives a strong push; as the disk gets close to the setpoint, the
//   push fades away.
//
// THIS MODULE IS WRITTEN TO BE REUSED, UNCHANGED
//   1. Enhancement E4 (PI control, in the Final Design Lab Project) builds a
//      PI controller AROUND this file: p_controller + an integrator + a sum +
//      a final limit.
//   2. The same file could control another plant, for example a boost
//      converter regulating a voltage instead of an angle.
//   That only works because the module knows nothing about the disk. The
//   reuse rules (checked by tb_p_controller):
//     - No plant constants inside. Nothing here imports disk_pkg. Every size
//       and limit is a parameter, set by the module that instantiates it.
//     - The output limits are parameters (OUT_MIN, OUT_MAX). The disk uses
//       -255 ... +255; a converter's duty cycle needs different limits; inside
//       a PI controller the P part is left unlimited and only the SUM is
//       limited. The control law is the same every time; only the limits
//       change.
//     - The sign convention is fixed: error = reference - measured. A positive
//       error means "the plant is below where it should be: push forward".
//     - The product is computed at full width, so it can never wrap around.
//
// Block diagram
//
//   reference --->(+)  error                  product           scaled
//                  |-----+---->[ x ]---------------->[ >>> FRAC_BITS ]---+
//   measured ---->(-)    |       ^                                       |
//                        |       kp                                      v
//                        +-----------------> error (output)       [ limit to ]
//                                                                 [ OUT_MIN  ]
//                                                                 [ OUT_MAX  ]
//                                                                       |
//                                       p_action <--[ register, loads on ]
//                                                   [ sample_tick        ]
//
// Worked examples, as the disk uses it (OUT_MIN = -255, OUT_MAX = +255,
// FRAC_BITS = 0; one count is about 0.18 degrees)
//
//   reference measured  error  kp  product  p_action  meaning
//   --------- --------  -----  --  -------  --------  -------------------------
//       512        0      512   2    1,024     +255   far away: full power fwd
//         0       40      -40   3     -120     -120   47% power, reverse
//       100       97        3   2        6       +6   close: 2% power (too weak
//                                                     to beat friction, so the
//                                                     disk may stop a little short)
//       100      100        0   9        0        0   on target: motor off
//
// The same module with different parameters (this is what reuse looks like)
//
//   parameters                       error  kp  product  scaled  p_action
//   -------------------------------  -----  --  -------  ------  --------
//   defaults: no limit                 512   2    1,024   1,024    1,024
//   OUT_MIN = -40, OUT_MAX = 200       512   2    1,024   1,024      200
//   FRAC_BITS = 2 (Kp = kp / 4)          7   3       21       5        5
//   FRAC_BITS = 2                       -7   3      -21      -6       -6
//
//   With FRAC_BITS = 2 the gain is kp / 4, so kp = 3 means Kp = 0.75. The
//   ">>>" is an ARITHMETIC right shift: it keeps the sign, and it rounds
//   DOWN (toward minus infinity), so 21 / 4 = 5.25 gives 5 and -21 / 4 =
//   -5.25 gives -6. (">>" would shift zeros in from the left and turn a
//   small negative number into a huge positive one.)
//
// Choosing Kp for the disk (measured on the bench, 100 Hz sample rate)
//   Kp = 1 sluggish, may stop short; Kp = 2 no overshoot; Kp = 3-4 faster, a
//   few degrees of overshoot; Kp = 5-6 rings for a long time; Kp = 7 and
//   above oscillates forever.
//
// Data types (the numbers are for the disk: IN_WIDTH = 16, KP_WIDTH = 4)
//   reference, measured : signed IN_WIDTH bits (16: -32,768 to +32,767)
//   error               : signed IN_WIDTH + 1 bits (17). The difference of two
//                         16-bit numbers needs one extra bit:
//                         32,767 - (-32,768) = 65,535.
//   kp                  : unsigned KP_WIDTH bits (4: 0 to 15, from switches)
//   product             : signed PRODUCT_WIDTH = IN_WIDTH + KP_WIDTH + 2 bits
//                         (22) = error (17) + kp with a 0 sign bit added (5).
//                         That is the full size of any product: the largest
//                         is 65,535 x 15 = 983,025, which needs 21 bits plus a
//                         sign. A product cut down to fewer bits would WRAP
//                         and change sign at the largest errors.
//   p_action            : signed OUT_WIDTH bits (9 for the disk: -255 to +255)
//
// Parameters
//   IN_WIDTH  : width of reference and measured. Default 16.
//   KP_WIDTH  : width of the unsigned gain kp. Default 4 (0 to 15).
//   FRAC_BITS : the gain is kp / 2^FRAC_BITS. Default 0 (a whole number).
//   OUT_WIDTH : width of p_action. Default IN_WIDTH + KP_WIDTH + 2, wide
//               enough for any product (at most 31).
//   OUT_MAX   : largest p_action.  Default: the largest OUT_WIDTH-bit value
//               (no limit).
//   OUT_MIN   : smallest p_action. Default: the smallest OUT_WIDTH-bit value
//               (no limit).
//
// Inputs
//   clk         : 100 MHz system clock
//   reset       : synchronous, active-high reset. Sets p_action to 0.
//   sample_tick : one-clock-cycle pulse at the sample rate (100 Hz for the
//                 disk). p_action only updates on these pulses.
//   reference   : where the plant should be (the disk: setpoint, in counts)
//   measured    : where the plant is (the disk: position, in counts)
//   kp          : proportional gain
//
// Outputs
//   error       : reference - measured, at every clock (not registered), so
//                 that an integrator built around this module can use the
//                 same error.
//   p_action    : the limited proportional action, registered: it changes
//                 only on sample_tick and holds between samples.
//
// Internal signals
//   product : kp x error, at full width, before scaling and limiting
//   scaled  : product >>> FRAC_BITS
//   wide    : scaled, sign-extended to the comparison width (CMP_WIDTH)
//==============================================================================

module p_controller #(
    parameter int IN_WIDTH  = 16,
    parameter int KP_WIDTH  = 4,
    parameter int FRAC_BITS = 0,
    parameter int OUT_WIDTH = IN_WIDTH + KP_WIDTH + 2,
    parameter int OUT_MAX   =  (2**(OUT_WIDTH - 1)) - 1,
    parameter int OUT_MIN   = -(2**(OUT_WIDTH - 1))
) (
    input  logic                        clk,
    input  logic                        reset,
    input  logic                        sample_tick,
    input  logic signed [IN_WIDTH-1:0]  reference,
    input  logic signed [IN_WIDTH-1:0]  measured,
    input  logic        [KP_WIDTH-1:0]  kp,
    output logic signed [IN_WIDTH:0]    error,
    output logic signed [OUT_WIDTH-1:0] p_action
);

    // error needs one bit more than its inputs; product is error x (kp plus a sign bit).
    localparam int PRODUCT_WIDTH = IN_WIDTH + 1 + KP_WIDTH + 1;            // 22 for the disk
    // The limits are compared at a width that holds both the product and the limits.
    localparam int CMP_WIDTH = (OUT_WIDTH > PRODUCT_WIDTH) ? OUT_WIDTH : PRODUCT_WIDTH;
    localparam logic signed [CMP_WIDTH-1:0] LIMIT_HIGH = CMP_WIDTH'(OUT_MAX);
    localparam logic signed [CMP_WIDTH-1:0] LIMIT_LOW  = CMP_WIDTH'(OUT_MIN);

    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [PRODUCT_WIDTH-1:0] scaled;
    logic signed [CMP_WIDTH-1:0]     wide;

    // Both inputs are signed, so SystemVerilog sign-extends them to the width
    // of "error" BEFORE subtracting. The result can never overflow.
    assign error = reference - measured;

    // kp is unsigned. Putting a 0 in front of it ({1'b0, kp}) and marking it
    // $signed makes it a positive signed number, so this is a signed multiply.
    // (If one operand were left unsigned, SystemVerilog would treat the WHOLE
    // multiply as unsigned, and negative errors would come out as huge
    // positive numbers.)
    assign product = error * $signed({1'b0, kp});

    // Undo the fixed-point scaling of the gain (no change when FRAC_BITS = 0).
    assign scaled = product >>> FRAC_BITS;

    // Sign-extend to the comparison width (scaled is signed, so the cast keeps the sign).
    assign wide = CMP_WIDTH'(scaled);

    // Limit, and register once per sample. The comparisons are done at full
    // width; only a value already known to be within the limits is cut down
    // to OUT_WIDTH bits.
    always_ff @(posedge clk) begin
        if (reset) begin
            p_action <= '0;
        end else if (sample_tick) begin
            if (wide > LIMIT_HIGH)
                p_action <= OUT_WIDTH'(LIMIT_HIGH);        // limit: OUT_MAX
            else if (wide < LIMIT_LOW)
                p_action <= OUT_WIDTH'(LIMIT_LOW);         // limit: OUT_MIN
            else
                p_action <= OUT_WIDTH'(wide);              // in range: keep the low bits
        end
    end

endmodule
