#include <cstdio>
#include <cstdint>
#include <SDL.h>
#include "Vsnake_top.h"
#include "verilated.h"

enum { H_VIS = 640, H_TOTAL = 800, V_VIS = 480, V_TOTAL = 525 };

static uint32_t pixels[V_VIS * H_VIS];

// seven-segment patterns (active-high), the same table as rtl/seg7.v
static int decode_digit(int seg) {
    static const int pat[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};
    for (int d = 0; d < 10; d++)
        if (seg == (~pat[d] & 0x7F)) return d;
    return 0;   // a blank digit counts as 0
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsnake_top* dut = new Vsnake_top;

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        printf("SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }
    SDL_Window* win = SDL_CreateWindow("Verilog Snake",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, H_VIS, V_VIS, 0);
    SDL_Renderer* ren = win ? SDL_CreateRenderer(win, -1, 0) : nullptr;
    if (win && !ren) ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    SDL_Texture* tex = ren ? SDL_CreateTexture(ren, SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING, H_VIS, V_VIS) : nullptr;
    if (!win || !ren || !tex) {
        printf("window setup failed: %s\n", SDL_GetError());
        return 1;
    }

    // reset the design, no buttons pressed
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

    printf("Arrow keys or WASD to steer, R to restart, Esc to quit.\n");

    bool running = true;
    bool tap_up = false, tap_right = false, tap_down = false, tap_left = false, tap_r = false;
    Uint32 fps_t0 = SDL_GetTicks();
    int fps_frames = 0;

    while (running) {
        Uint32 t_start = SDL_GetTicks();

        // --- keyboard: remember key-down events so a quick tap is never missed
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = false;
            if (e.type == SDL_KEYDOWN) {
                switch (e.key.keysym.scancode) {
                    case SDL_SCANCODE_UP:    case SDL_SCANCODE_W: tap_up    = true; break;
                    case SDL_SCANCODE_RIGHT: case SDL_SCANCODE_D: tap_right = true; break;
                    case SDL_SCANCODE_DOWN:  case SDL_SCANCODE_S: tap_down  = true; break;
                    case SDL_SCANCODE_LEFT:  case SDL_SCANCODE_A: tap_left  = true; break;
                    case SDL_SCANCODE_R:                          tap_r     = true; break;
                    case SDL_SCANCODE_ESCAPE:                     running   = false; break;
                    default: break;
                }
            }
        }
        const Uint8* k = SDL_GetKeyboardState(nullptr);
        dut->btn_up    = k[SDL_SCANCODE_UP]    || k[SDL_SCANCODE_W] || tap_up;
        dut->btn_right = k[SDL_SCANCODE_RIGHT] || k[SDL_SCANCODE_D] || tap_right;
        dut->btn_down  = k[SDL_SCANCODE_DOWN]  || k[SDL_SCANCODE_S] || tap_down;
        dut->btn_left  = k[SDL_SCANCODE_LEFT]  || k[SDL_SCANCODE_A] || tap_left;
        dut->restart   = k[SDL_SCANCODE_R] || tap_r;
        tap_up = tap_right = tap_down = tap_left = tap_r = false;

        // --- run the hardware for exactly one video frame
        for (int y = 0; y < V_TOTAL; y++) {
            for (int x = 0; x < H_TOTAL; x++) {
                if (x < H_VIS && y < V_VIS) {
                    uint32_t r = dut->r * 17, g = dut->g * 17, b = dut->b * 17;
                    pixels[y * H_VIS + x] = 0xFF000000u | (r << 16) | (g << 8) | b;
                }
                dut->clk = 1; dut->eval();
                dut->clk = 0; dut->eval();
            }
        }

        // --- show it
        SDL_UpdateTexture(tex, nullptr, pixels, H_VIS * (int)sizeof(uint32_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, nullptr, nullptr);
        SDL_RenderPresent(ren);

        // --- once a second: frame rate and score (read back from the display pins)
        fps_frames++;
        Uint32 now = SDL_GetTicks();
        if (now - fps_t0 >= 1000) {
            int len = decode_digit(dut->hex0) + 10 * decode_digit(dut->hex1)
                    + 100 * decode_digit(dut->hex2);
            char title[96];
            snprintf(title, sizeof(title), "Verilog Snake | length %d | %s | %d fps",
                     len, dut->game_over ? "GAME OVER (R to restart)" : "playing", fps_frames);
            SDL_SetWindowTitle(win, title);
            printf("%d fps, length %d\n", fps_frames, len);
            fps_frames = 0;
            fps_t0 = now;
        }

        // never run faster than 60 frames per second
        Uint32 spent = SDL_GetTicks() - t_start;
        if (spent < 16) SDL_Delay(16 - spent);
    }

    dut->final();
    delete dut;
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}