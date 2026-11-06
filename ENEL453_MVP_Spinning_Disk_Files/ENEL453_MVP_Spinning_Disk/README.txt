ENEL 453 MVP Design Lab Project: Spinning Disk Position Control
Design files
================================================================

What is in this folder
  rtl/                    the design: 16 SystemVerilog files, including disk_pkg.sv
                          (the package of shared constants) and disk_top.sv (the top level)
  tb/                     7 self-checking testbenches; each prints PASS or FAIL
  constraints/            disk_basys3.xdc, the Basys3 pin constraints, with the Pmod
                          pin diagrams and the wiring in its comments

Setting up the Vivado project
  Follow Appendix C of the handout. In short: a new RTL project for part
  xc7a35tcpg236-1; add every file in rtl/ as a design source (including
  disk_pkg.sv), constraints/disk_basys3.xdc as the constraints file, and every
  file in tb/ as a simulation source; set disk_top as the top module.

What you complete (handout Section 5)
  Step 4  quad_decoder.sv: the case statement has a TODO in place of the eight
          legal moves. Until you complete it, tb_quad_decoder and tb_disk_top
          FAIL. That is expected; the other five testbenches PASS.
  Step 5  The counts display on sw[10].
  Step 7  Make the design more modular (subsystems).

Rules
  - Read the header of each file: they are written to teach.
  - Do not change p_controller.sv. It is written to be reused unchanged.
  - Safety: do not arm the motor on the rig (sw[15] up) until tb_disk_top
    passes.
