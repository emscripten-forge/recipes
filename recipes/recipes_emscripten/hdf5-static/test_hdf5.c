/* Write a compressed 2-D dataset with an attribute, close, reopen, read. */
#include <hdf5.h>
#include <hdf5_hl.h>
#include <stdio.h>

int main(void)
{
    const char *path = "/tmp/test.h5";
    double data[4][6], back[4][6];
    hsize_t dims[2] = {4, 6}, chunk[2] = {2, 3};
    int i, j, bad = 0, version = 0;

    for (i = 0; i < 4; i++)
        for (j = 0; j < 6; j++)
            data[i][j] = i * 10 + j + 0.5;

    hid_t f = H5Fcreate(path, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    hid_t space = H5Screate_simple(2, dims, NULL);
    hid_t dcpl = H5Pcreate(H5P_DATASET_CREATE);
    H5Pset_chunk(dcpl, 2, chunk);
    H5Pset_deflate(dcpl, 6);
    hid_t d = H5Dcreate2(f, "x", H5T_NATIVE_DOUBLE, space, H5P_DEFAULT, dcpl, H5P_DEFAULT);
    H5Dwrite(d, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);
    H5Dclose(d);
    H5Pclose(dcpl);
    H5Sclose(space);
    version = 3;
    H5LTset_attribute_int(f, "x", "version", &version, 1);
    H5Fclose(f);

    version = 0;
    f = H5Fopen(path, H5F_ACC_RDONLY, H5P_DEFAULT);
    d = H5Dopen2(f, "x", H5P_DEFAULT);
    H5Dread(d, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, back);
    H5Dclose(d);
    H5LTget_attribute_int(f, "x", "version", &version);
    H5Fclose(f);

    for (i = 0; i < 4; i++)
        for (j = 0; j < 6; j++)
            if (back[i][j] != data[i][j])
                bad++;
    if (version != 3)
        bad++;
    printf("%s (HDF5 %d.%d.%d)\n", bad ? "FAILED" : "OK",
           H5_VERS_MAJOR, H5_VERS_MINOR, H5_VERS_RELEASE);
    return bad != 0;
}
