#include <flatcc/flatcc_builder.h>

int main(void) {
  flatcc_builder_t builder;
  flatcc_builder_init(&builder);
  flatcc_builder_clear(&builder);
  return 0;
}