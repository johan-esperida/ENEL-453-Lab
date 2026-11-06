`timescale 1ns / 1ps
//==============================================================================
// Module: synchronizer
//
// Purpose
//   Brings a signal from the outside world (a switch, a push-button, an encoder
//   channel) safely into the 100 MHz clock domain.
//
//   An outside signal can change at any moment, including right at a clock
//   edge. A flip-flop that samples it at that instant can go "metastable": its
//   output hovers between 0 and 1 for a short time before settling. Two
//   flip-flops in series give the first one a whole clock period (10 ns) to
//   settle before the second one passes the value on. The rest of the design
//   only ever uses the clean output q.
//
//   This is the two flip-flop synchronizer from lecture L7a (c420_sync), with a
//   WIDTH parameter added so that a group of switches can share one instance.
//
// Block diagram (one bit shown; WIDTH copies sit side by side)
//
//                 ________               ________
//                |        |    meta     |        |
//       d ------>|D      Q|------------>|D      Q|------> q
//                |        |             |        |
//       clk ---->|>       |     clk --->|>       |
//                |________|             |________|
//                first flip-flop        second flip-flop
//                (may go metastable)    (settled, safe to use)
//
// Timing: q follows d two clock edges later.
//
//       clk    __/--\__/--\__/--\__/--\__/--\__
//       d      _____/--------------------------    changes between clock edges
//       meta   ________/-----------------------    copied at the 1st rising edge
//       q      ______________/-----------------    copied at the 2nd rising edge
//
// No reset
//   Both flip-flops copy their input on every clock edge, so whatever value
//   they hold at power-up is flushed out after two clock cycles. Without a
//   reset, this module can also synchronize the reset button itself.
//
// Parameters
//   WIDTH : number of bits synchronized side by side (default 1)
//
// Inputs
//   clk : 100 MHz system clock
//   d   : asynchronous input from the outside world
//
// Outputs
//   q   : synchronized copy of d, two clock cycles later
//
// Internal signals
//   meta : output of the first flip-flop. It may be briefly metastable, so it
//          is never used anywhere except as the input of the second flip-flop.
//==============================================================================

module synchronizer #(
    parameter int WIDTH = 1
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

    logic [WIDTH-1:0] meta;

    always_ff @(posedge clk) begin
        meta <= d;     // first flip-flop: samples the outside signal
        q    <= meta;  // second flip-flop: passes on the settled value
    end

endmodule
