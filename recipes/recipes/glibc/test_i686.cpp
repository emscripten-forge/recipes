// Runs on the build machine: exercises libstdc++, exceptions (libgcc_s),
// threads and dynamic loading from the i686 sysroot.
#include <dlfcn.h>
#include <gnu/libc-version.h>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <thread>

int main() {
    static_assert(sizeof(void*) == 4, "expected a 32-bit target");
    std::map<std::string, int> m{{"a", 1}, {"b", 2}};
    int caught = 0;
    try {
        throw std::runtime_error("boom");
    } catch (const std::exception &e) {
        caught = (std::string(e.what()) == "boom");
    }
    int from_thread = 0;
    std::thread t([&] { from_thread = m["b"]; });
    t.join();
    void *h = dlopen("libm.so.6", RTLD_NOW);
    std::cout << "glibc " << gnu_get_libc_version() << ", caught=" << caught
              << ", thread=" << from_thread << ", dlopen(libm)=" << (h != nullptr)
              << std::endl;
    return (caught && from_thread == 2 && h) ? 0 : 1;
}
