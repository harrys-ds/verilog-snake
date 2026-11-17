#include <cstdio>
#include <cstdint>
#include "Vsnake_top.h"
#include "verilated.h"

enum { H_VIS = 640, H_TOTAL = 800, V_VIS = 480, V_TOTAL = 525 };

static uint8_t frame[V_VIS][H_VIS][3];

static void write_ppm(const char* name) {
    FILE* f = fopen(name, "wb");
    if (!f) { printf("cannot write %s\n", name); return; }
    fprintf(f, "P6\n%d %d\n255\n", H_VIS, V_VIS);
    fwrite(frame, 1, sizeof(frame), f);
    fclose(f);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsnake_top* dut = new Vsnake_top;

    // hold reset for a few clock cycles, no buttons pressed
    dut->rst = 1;
    dut->restart = 0;
    dut->btn_up = 0; dut->btn_right = 0; dut->btn_down = 0; dut->btn_left = 0;
    for (int i = 0; i < 8; i++) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
    }
    dut->clk = 0;
    dut->rst = 0;
    dut->eval();

    long sync_errors = 0;
    const int LAST_FRAME = 30;

    for (int f = 0; f <= LAST_FRAME; f++) {
        for (int i = 0; i < H_TOTAL * V_TOTAL; i++) {
            int x = i % H_TOTAL;
            int y = i / H_TOTAL;

            // the outputs are settled now, and belong to pixel (x, y)
            int want_hsync = !(x >= 656 && x < 752);
            int want_vsync = !(y >= 490 && y < 492);
            if (dut->hsync != want_hsync || dut->vsync != want_vsync)
                sync_errors++;

            if (x < H_VIS && y < V_VIS) {
                frame[y][x][0] = (uint8_t)(dut->r * 17);   // 4-bit -> 8-bit
                frame[y][x][1] = (uint8_t)(dut->g * 17);
                frame[y][x][2] = (uint8_t)(dut->b * 17);
            }

            dut->clk = 1; dut->eval();   // one full clock cycle
            dut->clk = 0; dut->eval();
        }

        if (f == 0 || f == LAST_FRAME) {
            char name[32];
            snprintf(name, sizeof(name), "vframe%d.ppm", f);
            write_ppm(name);
        }
    }

    printf("frames simulated: %d\n", LAST_FRAME + 1);
    printf("game_over: %d\n", (int)dut->game_over);
    printf("sync mismatches: %ld\n", sync_errors);

    dut->final();
    delete dut;
    return sync_errors == 0 ? 0 : 1;
}