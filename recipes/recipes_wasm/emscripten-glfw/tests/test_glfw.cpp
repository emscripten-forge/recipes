#include <GLFW/glfw3.h>
#include <GLFW/emscripten_glfw3.h>

#include <cstdio>

int main() {
    int major = 0;
    int minor = 0;
    int revision = 0;
    glfwGetVersion(&major, &minor, &revision);

    std::printf("GLFW %d.%d.%d\n", major, minor, revision);
    std::printf("version string: %s\n", glfwGetVersionString());
    std::printf("emscripten platform supported: %d\n",
                glfwPlatformSupported(GLFW_PLATFORM_EMSCRIPTEN));

    if (major != GLFW_VERSION_MAJOR ||
        minor != GLFW_VERSION_MINOR ||
        revision != GLFW_VERSION_REVISION) {
        std::fprintf(stderr, "runtime GLFW version does not match headers\n");
        return 1;
    }
    if (!glfwPlatformSupported(GLFW_PLATFORM_EMSCRIPTEN)) {
        std::fprintf(stderr, "Emscripten platform is not supported\n");
        return 1;
    }
    return 0;
}
