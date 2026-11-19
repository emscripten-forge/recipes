/* Resample a 440 Hz sine 44.1k -> 16k with the 32-bit (HQ) and 64-bit (VHQ)
 * engines; this runs the FFT callback tables that trapped with
 * "function signature mismatch" in wasm before the patch. */
#include <math.h>
#include <stdio.h>
#include <soxr.h>

#define IN_RATE 44100.
#define OUT_RATE 16000.
#define N_IN 44100
#define N_OUT 16000

static int check(unsigned long recipe) {
  static float in[N_IN], out[N_OUT];
  size_t odone = 0;
  double err = 0;
  int i;
  for (i = 0; i < N_IN; ++i) in[i] = (float)sin(2 * M_PI * 440 * i / IN_RATE);
  soxr_quality_spec_t q = soxr_quality_spec(recipe, 0);
  soxr_error_t e = soxr_oneshot(IN_RATE, OUT_RATE, 1, in, N_IN, NULL,
                                out, N_OUT, &odone, NULL, &q, NULL);
  if (e || odone != N_OUT) {
    printf("FAIL: %s odone=%zu\n", e ? e : "", odone);
    return 1;
  }
  /* away from the edges the output is the same sine at the new rate */
  for (i = 1000; i < N_OUT - 1000; ++i)
    err = fmax(err, fabs(out[i] - sin(2 * M_PI * 440 * i / OUT_RATE)));
  printf("recipe %lu: max error %g\n", recipe, err);
  return err > 1e-3;
}

int main(void) {
  printf("libsoxr %s\n", soxr_version());
  return check(SOXR_HQ) || check(SOXR_VHQ);
}
