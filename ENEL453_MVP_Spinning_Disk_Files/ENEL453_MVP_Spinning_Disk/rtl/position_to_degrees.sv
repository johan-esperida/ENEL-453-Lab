`timescale 1ns / 1ps
//==============================================================================
// Module: position_to_degrees
//
// Purpose
//   Converts the disk position in encoder counts into an angle in whole
//   degrees, 0 to 359, for the 7-segment display. Only the angle within one
//   revolution is shown: 1.5 revolutions displays as 180 degrees.
//
// Equations (COUNTS_PER_REV = 2048)
//
//   1. Position within one revolution, 0 to 2047:
//        count_in_rev = position modulo 2048 = the low 11 bits of position
//      Taking the low bits also works for negative positions, because of
//      two's complement:
//        position = -512 = 1111_1110_0000_0000 -> low 11 bits = 1536
//        and 1536 counts is 270 degrees, which is the same as -90 degrees.
//
//   2. Scale to degrees:
//        degrees = count_in_rev * 360 / 2048
//      Multiply first, then divide, so no precision is lost. Dividing by
//      2048 = 2^11 is just a right shift by 11 bits: free in hardware.
//
//   Examples:
//     position     count_in_rev   x 360      / 2048    degrees
//     --------     ------------   -------    -------   -------
//          0                0           0      0.00        0
//        512              512     184,320     90.00       90
//       -512             1536     552,960    270.00      270
//       2047             2047     736,920    359.82      359  (rounds down)
//       2048 (1 rev)        0           0      0.00        0
//
// Data types
//   count_in_rev    : unsigned 11 bits, 0 to 2047
//   count_times_360 : unsigned 20 bits; the largest value, 2047 x 360 =
//                     736,920, needs 20 bits (2^20 = 1,048,576)
//   degrees         : unsigned 9 bits, 0 to 359
//
// Constants (from disk_pkg)
//   COUNTS_PER_REV  : encoder counts per revolution, 2048. MUST be a power of two.
//   DEGREES_PER_REV : 360
//   POSITION_WIDTH  : width of position (16 bits, signed)
//   DEGREES_WIDTH   : width of degrees (9 bits)
//
// Inputs
//   position : signed disk position, in encoder counts
//
// Outputs
//   degrees  : angle within one revolution, 0 to 359 degrees
//
// Internal signals
//   count_in_rev    : position modulo one revolution
//   count_times_360 : count_in_rev x 360, before the divide
//==============================================================================

module position_to_degrees
    import disk_pkg::*;     // POSITION_WIDTH, DEGREES_WIDTH, COUNTS_PER_REV, DEGREES_PER_REV
(
    input  logic signed [POSITION_WIDTH-1:0] position,
    output logic        [DEGREES_WIDTH-1:0]  degrees
);

    localparam int REV_BITS     = $clog2(COUNTS_PER_REV);    // 11 bits count 0..2047
    localparam int SCALED_WIDTH = REV_BITS + DEGREES_WIDTH;  // 11 + 9 = 20 bits

    logic [REV_BITS-1:0]     count_in_rev;
    logic [SCALED_WIDTH-1:0] count_times_360;

    assign count_in_rev    = position[REV_BITS-1:0];                       // modulo 2048
    assign count_times_360 = count_in_rev * DEGREES_WIDTH'(DEGREES_PER_REV); // multiply first
    assign degrees         = DEGREES_WIDTH'(count_times_360 >> REV_BITS);    // then / 2048

endmodule
