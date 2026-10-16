## Basys3 Lab 5 constraints (xc7a35tcpg236-1)

## 100 MHz clock
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

## Display-mode switches: SW1:SW0
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {display_select[0]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {display_select[1]}]

## LEDs
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {led[8]}]
set_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS33} [get_ports {led[9]}]
set_property -dict {PACKAGE_PIN W3 IOSTANDARD LVCMOS33} [get_ports {led[10]}]
set_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS33} [get_ports {led[11]}]
set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {led[12]}]
set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports {led[13]}]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS33} [get_ports {led[14]}]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports {led[15]}]

## Seven-segment display
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports CA]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports CB]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports CC]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports CD]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports CE]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports CF]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports CG]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports DP]

set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports AN1]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports AN2]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports AN3]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports AN4]

## Centre pushbutton, active high
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports reset]

## JXADC channel 15 analog inputs
## Bank 35 is powered at 3.3 V on the Basys3. Explicitly setting LVCMOS33
## prevents Vivado from resolving these top-level ports to its LVCMOS18 default,
## which otherwise triggers DRC BIVC-1 against the 3.3 V LEDs in the same bank.
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports vauxp15]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports vauxn15]

## Configuration voltage
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
