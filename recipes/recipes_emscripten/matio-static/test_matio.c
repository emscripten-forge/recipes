/* Write a 3x2 double matrix to a compressed MAT 5 file and to a MAT 7.3
 * (HDF5) file, read both back. */
#include <matio.h>
#include <stdio.h>
#include <string.h>

static int roundtrip(const char *path, enum mat_ft version, enum matio_compression comp)
{
    double x[6] = {1, 2, 3, 4.5, 5.5, 6.5}, *y;
    size_t dims[2] = {3, 2};
    int bad = 0, i;

    mat_t *mat = Mat_CreateVer(path, NULL, version);
    if (!mat)
        return 1;
    matvar_t *v = Mat_VarCreate("x", MAT_C_DOUBLE, MAT_T_DOUBLE, 2, dims, x, 0);
    Mat_VarWrite(mat, v, comp);
    Mat_VarFree(v);
    Mat_Close(mat);

    mat = Mat_Open(path, MAT_ACC_RDONLY);
    if (!mat)
        return 1;
    if (Mat_GetVersion(mat) != version)
        bad++;
    v = Mat_VarRead(mat, "x");
    if (!v || v->rank != 2 || v->dims[0] != 3 || v->dims[1] != 2)
        bad++;
    else
        for (y = v->data, i = 0; i < 6; i++)
            if (y[i] != x[i])
                bad++;
    Mat_VarFree(v);
    Mat_Close(mat);
    return bad;
}

int main(void)
{
    int major, minor, release;
    int bad = roundtrip("/tmp/t5.mat", MAT_FT_MAT5, MAT_COMPRESSION_ZLIB)
            + roundtrip("/tmp/t73.mat", MAT_FT_MAT73, MAT_COMPRESSION_NONE);
    Mat_GetLibraryVersion(&major, &minor, &release);
    printf("%s (matio %d.%d.%d)\n", bad ? "FAILED" : "OK", major, minor, release);
    return bad != 0;
}
