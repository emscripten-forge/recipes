// raylib test that needs no window / GL context: image, color and math API
#include <stdio.h>
#include <string.h>

#include "raylib.h"
#include "raymath.h"

#define CHECK(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            fprintf(stderr, "line %d: CHECK failed: %s\n", __LINE__, #cond); \
            return 1;                                                        \
        }                                                                    \
    } while (0)

static int same_color(Color a, Color b) {
    return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
}

int main(void) {
    // raymath
    Vector2 v = Vector2Add((Vector2){1.0f, 2.0f}, (Vector2){3.0f, 4.0f});
    CHECK(v.x == 4.0f && v.y == 6.0f);
    CHECK(FloatEquals(Vector3Length((Vector3){3.0f, 4.0f, 0.0f}), 5.0f));
    Matrix m = MatrixTranslate(1.0f, 2.0f, 3.0f);
    Vector3 p = Vector3Transform((Vector3){0.0f, 0.0f, 0.0f}, m);
    CHECK(p.x == 1.0f && p.y == 2.0f && p.z == 3.0f);

    // rtext / rcore helpers
    CHECK(strcmp(TextFormat("%d-%s", 42, "ray"), "42-ray") == 0);
    CHECK(TextToInteger("1234") == 1234);

    // rtextures (CPU side)
    Image img = GenImageColor(16, 8, RED);
    CHECK(img.width == 16 && img.height == 8);
    ImageDrawPixel(&img, 3, 4, BLUE);
    CHECK(same_color(GetImageColor(img, 3, 4), BLUE));
    CHECK(same_color(GetImageColor(img, 0, 0), RED));
    ImageResizeNN(&img, 32, 16);
    CHECK(img.width == 32 && img.height == 16);
    CHECK(same_color(GetImageColor(img, 6, 8), BLUE));
    CHECK(ExportImage(img, "test.png"));
    UnloadImage(img);

    Image loaded = LoadImage("test.png");
    CHECK(loaded.width == 32 && loaded.height == 16);
    CHECK(same_color(GetImageColor(loaded, 7, 9), BLUE));
    UnloadImage(loaded);

    CHECK(ColorToInt(WHITE) == -1);

    printf("raylib test passed\n");
    return 0;
}
