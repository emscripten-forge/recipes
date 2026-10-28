#include <gflags/gflags.h>

DEFINE_int32(answer, 7, "test flag");

int main(int argc, char** argv) {
  gflags::SetUsageMessage("gflags smoke test");
  gflags::ParseCommandLineFlags(&argc, &argv, true);
  return FLAGS_answer == 7 ? 0 : 1;
}