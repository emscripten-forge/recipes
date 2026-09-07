#include <stdio.h>
#include <string.h>
#include <gdal.h>
#include <ogr_api.h>
#include <ogr_srs_api.h>

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { \
            fprintf(stderr, "FAIL: %s\n", msg); \
            return 1; \
        } \
    } while (0)

int main(void) {
    const char *version = GDALVersionInfo("RELEASE_NAME");
    printf("GDAL version: %s\n", version ? version : "(null)");
    CHECK(version && strncmp(version, "3.", 2) == 0, "GDALVersionInfo did not return a 3.x string");

    GDALAllRegister();
    int driver_count = GDALGetDriverCount();
    printf("GDAL driver count: %d\n", driver_count);
    CHECK(driver_count > 0, "no GDAL drivers registered");

    char *wkt_a = "POLYGON((0 0,2 0,2 2,0 2,0 0))";
    char *wkt_b = "POLYGON((1 1,3 1,3 3,1 3,1 1))";
    OGRGeometryH g_a = NULL;
    OGRGeometryH g_b = NULL;
    OGRErr err;

    err = OGR_G_CreateFromWkt(&wkt_a, NULL, &g_a);
    CHECK(err == OGRERR_NONE && g_a, "OGR_G_CreateFromWkt failed for g_a");
    err = OGR_G_CreateFromWkt(&wkt_b, NULL, &g_b);
    CHECK(err == OGRERR_NONE && g_b, "OGR_G_CreateFromWkt failed for g_b");

    OGRGeometryH intersection = OGR_G_Intersection(g_a, g_b);
    CHECK(intersection, "OGR_G_Intersection returned NULL (GEOS link broken?)");

    double area = OGR_G_Area(intersection);
    printf("intersection area: %f\n", area);
    CHECK(area > 0.99 && area < 1.01, "OGR_G_Intersection area is wrong");

    OGR_G_DestroyGeometry(intersection);
    OGR_G_DestroyGeometry(g_b);
    OGR_G_DestroyGeometry(g_a);

    printf("All tests passed\n");
    return 0;
}
