# Verilog Snake

A Snake game built from scratch in Verilog, simulated with Icarus Verilog. The long-term goal is to build a small RISC-V CPU on top of what I learn here.

**Status:** in progress. The VGA timing generator is done and verified. Everything is verified in simulation only, with no FPGA hardware yet.

## What's done

- [x] VGA sync generator (640x480 @ 60 Hz) with a self-checking testbench
- [ ] Drawing a square on screen
- [ ] 20x15 game grid
- [ ] Game tick timer
- [ ] Snake movement and body storage
- [ ] Food (LFSR), growth, and collisions
- [ ] Game state machine and score display

## VGA timing

The monitor needs sync pulses to know where each line and frame starts. A counter pair generates them from a 25 MHz pixel clock:

| | Visible | Front porch | Sync | Back porch | Total |
|---|---|---|---|---|---|
| Horizontal | 640 | 16 | 96 | 48 | 800 |
| Vertical | 480 | 10 | 2 | 33 | 525 |

Both sync signals are active low.

![hsync waveform](docs/hsync_waveform.png)

The testbench checks that `hsync` is low for 96 clocks per line, `vsync` is low for 1600 clocks per frame (2 lines), and `active` is high for 640 x 480 = 307200 clocks per frame.

## Run it

Requires [Icarus Verilog](https://bleyer.org/icarus/) and GTKWave.

```
iverilog -o sim rtl/vga_sync.v tb/vga_sync_tb.v
vvp sim
gtkwave vga_sync.vcd
```

Expected output ends with `PASS`.

## Layout

```
rtl/    Verilog design files
tb/     Testbenches
docs/   Diagrams and waveform screenshots
```
