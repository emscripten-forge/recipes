/* Forward + backward complex DFT (double) and real DFT (float): the input
 * comes back, and the transform of a cosine has its two peaks. */
#include <complex.h>
#include <fftw3.h>
#include <math.h>
#include <stdio.h>

#define N 64

int main(void)
{
    int i, bad = 0;

    fftw_complex *in = fftw_malloc(sizeof(fftw_complex) * N);
    fftw_complex *out = fftw_malloc(sizeof(fftw_complex) * N);
    fftw_complex *back = fftw_malloc(sizeof(fftw_complex) * N);
    fftw_plan fwd = fftw_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
    fftw_plan bwd = fftw_plan_dft_1d(N, out, back, FFTW_BACKWARD, FFTW_ESTIMATE);
    for (i = 0; i < N; i++)
        in[i] = cos(2 * M_PI * 3 * i / N) + I * sin(2 * M_PI * 5 * i / N);
    fftw_execute(fwd);
    fftw_execute(bwd);
    for (i = 0; i < N; i++)
        if (cabs(back[i] / N - in[i]) > 1e-12)
            bad++;
    fftw_destroy_plan(fwd);
    fftw_destroy_plan(bwd);
    fftw_free(in);
    fftw_free(out);
    fftw_free(back);

    float *rin = fftwf_malloc(sizeof(float) * N);
    fftwf_complex *rout = fftwf_malloc(sizeof(fftwf_complex) * (N / 2 + 1));
    fftwf_plan rp = fftwf_plan_dft_r2c_1d(N, rin, rout, FFTW_ESTIMATE);
    for (i = 0; i < N; i++)
        rin[i] = cosf(2 * (float)M_PI * 4 * i / N);
    fftwf_execute(rp);
    for (i = 0; i <= N / 2; i++) {
        float expect = (i == 4) ? N / 2.0f : 0.0f;
        if (fabsf(cabsf(rout[i]) - expect) > 1e-3f)
            bad++;
    }
    fftwf_destroy_plan(rp);
    fftwf_free(rin);
    fftwf_free(rout);

    printf("%s (fftw %s)\n", bad ? "FAILED" : "OK", fftw_version);
    return bad != 0;
}
