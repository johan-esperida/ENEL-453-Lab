##==============================================================================
## Rotating-disk position controller: Basys3 constraints
## FPGA part: xc7a35tcpg236-1 (Basys3 rev B)
##
## Each line ties one top-level port of disk_top to one physical FPGA pin, and
## sets its voltage standard (LVCMOS33 = 3.3 V logic).
##==============================================================================

##------------------------------------------------------------------------------
## Clock: 100 MHz oscillator on the board
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -name sys_clk -period 10.000 [get_ports clk]

##------------------------------------------------------------------------------
## Push-buttons (1 while pressed)
##
##                 [btnU]
##        [btnL]   [btnC]   [btnR]
##                 [btnD]
##
##   btnC = reset, btnL = setpoint -90 degrees, btnR = setpoint +90 degrees
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset_button]      ;# btnC
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports step_down_button]  ;# btnL
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports step_up_button]    ;# btnR

##------------------------------------------------------------------------------
## Slide switches (1 = up)
##
##   sw[15] ... sw[4] sw[3] sw[2] sw[1] sw[0]      <- sw[0] is at the RIGHT end
##   arm             |<------- Kp, 0-15 ------->|
##
##   Kp examples: 0010 = 2 (a good first value), 0100 = 4, 0111 = 7 (oscillates)
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {kp_switches[0]}]  ;# sw[0]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {kp_switches[1]}]  ;# sw[1]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {kp_switches[2]}]  ;# sw[2]
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {kp_switches[3]}]  ;# sw[3]
set_property -dict { PACKAGE_PIN R2  IOSTANDARD LVCMOS33 } [get_ports arm_switch]        ;# sw[15]

##------------------------------------------------------------------------------
## LEDs (above the switches; led[0] is at the RIGHT end)
##   led[3:0] = Kp   led[8] = encoder A   led[9] = encoder B
##   led[13] = reverse   led[14] = forward   led[15] = motor armed
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {led[8]}]
set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports {led[9]}]
set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports {led[10]}]
set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports {led[11]}]
set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports {led[12]}]
set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports {led[13]}]
set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports {led[14]}]
set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports {led[15]}]

##------------------------------------------------------------------------------
## 7-segment display (all active low: 0 = lit / digit on)
##   Segments CA..CG and DP are shared by all four digits; AN1..AN4 pick the
##   digit. AN1 is the RIGHTMOST digit.
##
##          A
##        -----
##     F |     | B         digit:  [AN4] [AN3] [AN2] [AN1]
##       |  G  |                    left              right
##        -----
##     E |     | C
##       |     |
##        -----   . DP
##          D
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W7  IOSTANDARD LVCMOS33 } [get_ports CA]
set_property -dict { PACKAGE_PIN W6  IOSTANDARD LVCMOS33 } [get_ports CB]
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports CC]
set_property -dict { PACKAGE_PIN V8  IOSTANDARD LVCMOS33 } [get_ports CD]
set_property -dict { PACKAGE_PIN U5  IOSTANDARD LVCMOS33 } [get_ports CE]
set_property -dict { PACKAGE_PIN V5  IOSTANDARD LVCMOS33 } [get_ports CF]
set_property -dict { PACKAGE_PIN U7  IOSTANDARD LVCMOS33 } [get_ports CG]
set_property -dict { PACKAGE_PIN V7  IOSTANDARD LVCMOS33 } [get_ports DP]
set_property -dict { PACKAGE_PIN U2  IOSTANDARD LVCMOS33 } [get_ports AN1]
set_property -dict { PACKAGE_PIN U4  IOSTANDARD LVCMOS33 } [get_ports AN2]
set_property -dict { PACKAGE_PIN V4  IOSTANDARD LVCMOS33 } [get_ports AN3]
set_property -dict { PACKAGE_PIN W4  IOSTANDARD LVCMOS33 } [get_ports AN4]

##------------------------------------------------------------------------------
## Pmod connectors: pin numbering
##
## Every Pmod connector has 12 pins in two rows of six. In each row, the two
## pins at one end are GND and 3V3 (3.3 V). Signal pin 1 is at the OTHER end,
## farthest from GND and 3V3. As seen looking straight into the connector:
##
##           power                 signal pins
##        +------+------+------+------+------+------+
##        | 3V3  | GND  |  4   |  3   |  2   |  1   |   <- row 1 (upper row)
##        +------+------+------+------+------+------+
##        | 3V3  | GND  |  10  |  9   |  8   |  7   |   <- row 2 (lower row)
##        +------+------+------+------+------+------+
##
## Pins 1 and 2 sit side by side in the SAME row; pin 7 is directly across
## from pin 1 in the other row. A common wiring mistake is to use pin 7 where
## pin 2 was meant.
##
## To check which pins are GND and 3V3: with the board powered, a meter reads
## 3.3 V between them.
##
## Do NOT connect anything to a 3V3 pin in this project.
##------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## Pmod JB: quadrature encoder (US Digital, label "B 5v A I G")
##
##   Encoder wire      Connect to
##   ---------------   -----------------------------------------------
##   white  (A)        2.2 k resistor, then JB pin 1  (ch_a)
##   brown  (B)        2.2 k resistor, then JB pin 2  (ch_b)
##   black  (G, GND)   JB pin 5  (GND)
##   red    (5v)       L298N "5V" screw terminal (NOT a Pmod pin)
##   green  (I, index) not connected
##
##   The encoder outputs are 5 V signals and the FPGA pins are 3.3 V. The 2.2 k
##   series resistors keep the current into the pins' protection diodes below
##   about 0.5 mA: (5 V - 3.3 V - 0.5 V) / (2.2 k + 0.2 k on the board).
##   Without them, the board's 200 ohm alone (JA, JB, JC; JXADC has 100 ohm)
##   would allow about 6 mA, over half the FPGA's 10 mA per-pin limit (Artix-7
##   data sheet DS181, Table 2).
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports ch_a]   ;# JB pin 1
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports ch_b]   ;# JB pin 2

##------------------------------------------------------------------------------
## Pmod JC: L298N motor driver
##
##   Basys3            L298N
##   ---------------   ---------------------------------------------------
##   JC pin 1          IN3  (motor_in1: forward)
##   JC pin 2          IN4  (motor_in2: reverse)
##   JC pin 3          ENB  (motor_en: PWM). Remove the ENB jumper first.
##   JC pin 5 (GND)    GND screw terminal: the Basys3, L298N and 12 V
##                     supply MUST share this ground
##
##   Power: 12 V supply (+) -> L298N "12V" terminal, (-) -> L298N GND.
##          Motor -> L298N OUT3 and OUT4. If the disk runs away instead of
##          holding position, turn the motor off (sw[15] down) and swap the
##          two motor wires.
##   If the motor is on OUT1/OUT2 instead, use IN1, IN2 and ENA.
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports motor_in1]  ;# JC pin 1
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports motor_in2]  ;# JC pin 2
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports motor_en]   ;# JC pin 3

##------------------------------------------------------------------------------
## Configuration settings (the same for every Basys3 design)
##------------------------------------------------------------------------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO        [current_design]
