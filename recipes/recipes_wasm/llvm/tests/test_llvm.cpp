#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/ThreadPool.h"
#include "llvm/Support/raw_ostream.h"
#include <chrono>

static_assert(!LLVM_ENABLE_THREADS, "Expected single-threaded LLVM");
#ifdef __EMSCRIPTEN_PTHREADS__
#error This consumer must link without pthread support.
#endif

int main() {
  llvm::LLVMContext context;
  llvm::Module module("llvm-static-test", context);
  module.print(llvm::outs(), nullptr);
  // Exercise the deferred-future path that can retain pthread symbols.
  llvm::DefaultThreadPool pool(llvm::hardware_concurrency(1));
  bool ran = false;
  auto result = pool.async([&] { ran = true; });
  if (ran || result.wait_for(std::chrono::seconds(0)) !=
                 std::future_status::deferred)
    return 1;
  pool.wait();
  result.get();
  return ran && module.getModuleIdentifier() == "llvm-static-test" ? 0 : 1;
}
