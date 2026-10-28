#include <SDL3/SDL.h>

#include <stdio.h>

int main(void)
{
    const int linked = SDL_GetVersion();
    printf("SDL %d.%d.%d (%s)\n",
           SDL_VERSIONNUM_MAJOR(linked),
           SDL_VERSIONNUM_MINOR(linked),
           SDL_VERSIONNUM_MICRO(linked),
           SDL_GetRevision());

    if (linked != SDL_VERSION) {
        fprintf(stderr, "linked SDL version doesn't match the headers\n");
        return 1;
    }

    if (!SDL_Init(0)) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Surface *surface = SDL_CreateSurface(64, 64, SDL_PIXELFORMAT_RGBA32);
    if (!surface) {
        fprintf(stderr, "SDL_CreateSurface failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Rect rect = { 0, 0, 64, 64 };
    const Uint32 red = SDL_MapSurfaceRGBA(surface, 255, 0, 0, 255);
    if (!SDL_FillSurfaceRect(surface, &rect, red)) {
        fprintf(stderr, "SDL_FillSurfaceRect failed: %s\n", SDL_GetError());
        return 1;
    }

    Uint8 r = 0;
    Uint8 g = 0;
    Uint8 b = 0;
    Uint8 a = 0;
    if (!SDL_ReadSurfacePixel(surface, 32, 32, &r, &g, &b, &a)) {
        fprintf(stderr, "SDL_ReadSurfacePixel failed: %s\n", SDL_GetError());
        return 1;
    }
    printf("pixel: %u %u %u %u\n", r, g, b, a);

    SDL_DestroySurface(surface);
    SDL_Quit();

    if (r != 255 || g != 0 || b != 0 || a != 255) {
        fprintf(stderr, "unexpected pixel color\n");
        return 1;
    }

    puts("SDL3 smoke test passed");
    return 0;
}
