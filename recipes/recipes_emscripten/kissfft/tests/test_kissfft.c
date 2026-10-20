#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "kiss_fft.h"
#include "kiss_fftr.h"

static const float TOLERANCE = 1e-4f;

static int test_complex_fft(int nfft) {
    kiss_fft_cfg cfg_fwd = kiss_fft_alloc(nfft, 0, NULL, NULL);
    kiss_fft_cfg cfg_inv = kiss_fft_alloc(nfft, 1, NULL, NULL);

    if (!cfg_fwd || !cfg_inv) {
        printf("FAIL: kiss_fft_alloc returned NULL for nfft=%d\n", nfft);
        return 1;
    }

    kiss_fft_cpx *in = (kiss_fft_cpx *)malloc(nfft * sizeof(kiss_fft_cpx));
    kiss_fft_cpx *freq = (kiss_fft_cpx *)malloc(nfft * sizeof(kiss_fft_cpx));
    kiss_fft_cpx *out = (kiss_fft_cpx *)malloc(nfft * sizeof(kiss_fft_cpx));

    if (!in || !freq || !out) {
        printf("FAIL: malloc failed for nfft=%d\n", nfft);
        free(in); free(freq); free(out);
        kiss_fft_free(cfg_fwd); kiss_fft_free(cfg_inv);
        return 1;
    }

    /* Fill input with test signal */
    for (int i = 0; i < nfft; i++) {
        in[i].r = sinf(2.0f * M_PI * 3.0f * i / nfft)
                + 0.5f * cosf(2.0f * M_PI * 7.0f * i / nfft);
        in[i].i = 0.0f;
    }

    /* Forward FFT */
    kiss_fft(cfg_fwd, in, freq);

    /* Verify DC bin is real (sum of input, all imaginary parts were zero) */
    if (fabsf(freq[0].i) > TOLERANCE) {
        printf("FAIL: DC bin imaginary part should be ~0, got %f (nfft=%d)\n", freq[0].i, nfft);
        free(in); free(freq); free(out);
        kiss_fft_free(cfg_fwd); kiss_fft_free(cfg_inv);
        return 1;
    }

    /* Inverse FFT */
    kiss_fft(cfg_inv, freq, out);

    /* Scale and verify roundtrip */
    float max_err = 0.0f;
    for (int i = 0; i < nfft; i++) {
        float scaled_r = out[i].r / nfft;
        float scaled_i = out[i].i / nfft;
        float err_r = fabsf(scaled_r - in[i].r);
        float err_i = fabsf(scaled_i - in[i].i);
        if (err_r > max_err) max_err = err_r;
        if (err_i > max_err) max_err = err_i;
    }

    if (max_err > TOLERANCE) {
        printf("FAIL: complex FFT roundtrip error %f exceeds tolerance (nfft=%d)\n", max_err, nfft);
        free(in); free(freq); free(out);
        kiss_fft_free(cfg_fwd); kiss_fft_free(cfg_inv);
        return 1;
    }

    printf("PASS: complex FFT roundtrip nfft=%d, max_err=%g\n", nfft, max_err);

    free(in); free(freq); free(out);
    kiss_fft_free(cfg_fwd); kiss_fft_free(cfg_inv);
    return 0;
}

static int test_real_fft(int nfft) {
    kiss_fftr_cfg cfg_fwd = kiss_fftr_alloc(nfft, 0, NULL, NULL);
    kiss_fftr_cfg cfg_inv = kiss_fftr_alloc(nfft, 1, NULL, NULL);

    if (!cfg_fwd || !cfg_inv) {
        printf("FAIL: kiss_fftr_alloc returned NULL for nfft=%d\n", nfft);
        return 1;
    }

    kiss_fft_scalar *in = (kiss_fft_scalar *)malloc(nfft * sizeof(kiss_fft_scalar));
    int nfreq = nfft / 2 + 1;
    kiss_fft_cpx *freq = (kiss_fft_cpx *)malloc(nfreq * sizeof(kiss_fft_cpx));
    kiss_fft_scalar *out = (kiss_fft_scalar *)malloc(nfft * sizeof(kiss_fft_scalar));

    if (!in || !freq || !out) {
        printf("FAIL: malloc failed for real FFT nfft=%d\n", nfft);
        free(in); free(freq); free(out);
        kiss_fftr_free(cfg_fwd); kiss_fftr_free(cfg_inv);
        return 1;
    }

    /* Fill input with real test signal */
    for (int i = 0; i < nfft; i++) {
        in[i] = sinf(2.0f * M_PI * 3.0f * i / nfft)
              + 0.5f * cosf(2.0f * M_PI * 7.0f * i / nfft);
    }

    /* Forward real FFT */
    kiss_fftr(cfg_fwd, in, freq);

    /* Inverse real FFT */
    kiss_fftri(cfg_inv, freq, out);

    /* Scale and verify roundtrip */
    float max_err = 0.0f;
    for (int i = 0; i < nfft; i++) {
        float scaled = out[i] / nfft;
        float err = fabsf(scaled - in[i]);
        if (err > max_err) max_err = err;
    }

    if (max_err > TOLERANCE) {
        printf("FAIL: real FFT roundtrip error %f exceeds tolerance (nfft=%d)\n", max_err, nfft);
        free(in); free(freq); free(out);
        kiss_fftr_free(cfg_fwd); kiss_fftr_free(cfg_inv);
        return 1;
    }

    printf("PASS: real FFT roundtrip nfft=%d, max_err=%g\n", nfft, max_err);

    free(in); free(freq); free(out);
    kiss_fftr_free(cfg_fwd); kiss_fftr_free(cfg_inv);
    return 0;
}

int main(void) {
    int failures = 0;
    int test_sizes[] = {8, 16, 32, 64, 128, 256, 1024};
    int num_sizes = sizeof(test_sizes) / sizeof(test_sizes[0]);

    printf("=== kissfft tests ===\n\n");

    /* Test complex FFT with various sizes */
    for (int i = 0; i < num_sizes; i++) {
        failures += test_complex_fft(test_sizes[i]);
    }

    /* Test real FFT with various sizes */
    for (int i = 0; i < num_sizes; i++) {
        failures += test_real_fft(test_sizes[i]);
    }

    printf("\n=== %d tests failed ===\n", failures);

    return failures > 0 ? 1 : 0;
}
