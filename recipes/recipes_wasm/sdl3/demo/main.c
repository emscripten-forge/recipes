/*
 * SDL3 WebAssembly demo.
 *
 * The structure follows the SDL3 main callbacks documented for Emscripten:
 * SDL_AppInit() only performs startup, and SDL_AppIterate() draws one frame
 * and returns quickly.
 *
 * This demo is based on the public-domain SDL renderer examples.
 */

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static int frame_count = 0;
static int max_frames = 0;

static void parse_args(int argc, char *argv[])
{
    for (int i = 1; i < argc; ++i) {
        if (SDL_strncmp(argv[i], "--driver=", 9) == 0) {
            SDL_SetHint(SDL_HINT_VIDEO_DRIVER, argv[i] + 9);
        } else if (SDL_strcmp(argv[i], "--driver") == 0 && i + 1 < argc) {
            SDL_SetHint(SDL_HINT_VIDEO_DRIVER, argv[++i]);
        } else if (SDL_strncmp(argv[i], "--frames=", 9) == 0) {
            max_frames = SDL_atoi(argv[i] + 9);
        } else if (SDL_strcmp(argv[i], "--frames") == 0 && i + 1 < argc) {
            max_frames = SDL_atoi(argv[++i]);
        }
    }
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
{
    (void)appstate;

    SDL_SetAppMetadata("SDL3 wasm demo", "1.0", "org.emscriptenforge.sdl3-demo");

    const char *frames = SDL_getenv("SDL_DEMO_FRAMES");
    if (frames && *frames) {
        max_frames = SDL_atoi(frames);
    }
    parse_args(argc, argv);

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer("SDL3 wasm demo", 640, 480,
                                     SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_SetRenderVSync(renderer, 1)) {
        SDL_Log("Couldn't enable vsync: %s", SDL_GetError());
    }

    SDL_SetRenderLogicalPresentation(renderer, 640, 480,
                                     SDL_LOGICAL_PRESENTATION_LETTERBOX);

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
    (void)appstate;

    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
    (void)appstate;

    const double now = (double)SDL_GetTicks() / 1000.0;
    const float red = (float)(0.5 + 0.5 * SDL_sin(now));
    const float green = (float)(0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2.0 / 3.0));
    const float blue = (float)(0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4.0 / 3.0));

    SDL_SetRenderDrawColorFloat(renderer, red, green, blue, SDL_ALPHA_OPAQUE_FLOAT);
    SDL_RenderClear(renderer);

    const SDL_FRect rect = { 220.0f, 160.0f, 200.0f, 160.0f };
    SDL_SetRenderDrawColorFloat(renderer, 1.0f - red, 1.0f - green, 1.0f - blue,
                                SDL_ALPHA_OPAQUE_FLOAT);
    SDL_RenderFillRect(renderer, &rect);

    SDL_RenderPresent(renderer);

    frame_count++;
    if (max_frames > 0 && frame_count >= max_frames) {
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
    (void)appstate;
    (void)result;

    SDL_Log("SDL3 demo finished after %d frame(s)", frame_count);
}
