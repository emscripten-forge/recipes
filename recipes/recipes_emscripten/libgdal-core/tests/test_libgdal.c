#include <math.h>
#include <stdio.h>
#include <string.h>
#include <gdal.h>
#include <ogr_api.h>
#include <ogr_srs_api.h>

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { \
            fprintf(stderr, "  FAIL: %s\n", msg); \
            return 1; \
        } \
    } while (0)

static int test_gdal_basics(void) {
    const char *version = GDALVersionInfo("RELEASE_NAME");
    printf("  GDAL version: %s\n", version ? version : "(null)");
    CHECK(version && strncmp(version, "3.", 2) == 0, "GDALVersionInfo did not return a 3.x string");

    GDALAllRegister();
    int driver_count = GDALGetDriverCount();
    printf("  GDAL driver count: %d\n", driver_count);
    CHECK(driver_count > 0, "no GDAL drivers registered");
    return 0;
}

/* Exercises the libgeos_c.so link: OGR_G_Intersection dispatches into GEOS. */
static int test_geos_intersection(void) {
    char *wkt_a = "POLYGON((0 0,2 0,2 2,0 2,0 0))";
    char *wkt_b = "POLYGON((1 1,3 1,3 3,1 3,1 1))";
    OGRGeometryH g_a = NULL;
    OGRGeometryH g_b = NULL;

    CHECK(OGR_G_CreateFromWkt(&wkt_a, NULL, &g_a) == OGRERR_NONE && g_a, "OGR_G_CreateFromWkt failed for g_a");
    CHECK(OGR_G_CreateFromWkt(&wkt_b, NULL, &g_b) == OGRERR_NONE && g_b, "OGR_G_CreateFromWkt failed for g_b");

    OGRGeometryH intersection = OGR_G_Intersection(g_a, g_b);
    CHECK(intersection, "OGR_G_Intersection returned NULL (GEOS link broken?)");

    double area = OGR_G_Area(intersection);
    printf("  intersection area: %f\n", area);
    CHECK(area > 0.99 && area < 1.01, "OGR_G_Intersection area is wrong");

    OGR_G_DestroyGeometry(intersection);
    OGR_G_DestroyGeometry(g_b);
    OGR_G_DestroyGeometry(g_a);
    return 0;
}

/* Exercises the libproj.so link: OCTTransform dispatches into PROJ. */
static int test_proj_transform(void) {
    OGRSpatialReferenceH src = OSRNewSpatialReference(NULL);
    OGRSpatialReferenceH dst = OSRNewSpatialReference(NULL);
    CHECK(src && dst, "OSRNewSpatialReference failed");
    CHECK(OSRImportFromEPSG(src, 4326) == OGRERR_NONE, "OSRImportFromEPSG 4326 failed");
    CHECK(OSRImportFromEPSG(dst, 3857) == OGRERR_NONE, "OSRImportFromEPSG 3857 failed");
    OSRSetAxisMappingStrategy(src, OAMS_TRADITIONAL_GIS_ORDER);
    OSRSetAxisMappingStrategy(dst, OAMS_TRADITIONAL_GIS_ORDER);

    OGRCoordinateTransformationH ct = OCTNewCoordinateTransformation(src, dst);
    CHECK(ct, "OCTNewCoordinateTransformation returned NULL (PROJ link broken?)");

    double x = 10.0, y = 50.0;
    int ok = OCTTransform(ct, 1, &x, &y, NULL);
    printf("  transform (10, 50) EPSG:4326 -> EPSG:3857: (%f, %f)\n", x, y);
    CHECK(ok, "OCTTransform failed");
    CHECK(fabs(x - 1113194.9) < 1.0, "web-mercator x is wrong");
    CHECK(fabs(y - 6446275.8) < 1.0, "web-mercator y is wrong");

    OCTDestroyCoordinateTransformation(ct);
    OSRDestroySpatialReference(dst);
    OSRDestroySpatialReference(src);
    return 0;
}

typedef int (*test_fn)(void);
struct test_case { const char *name; test_fn fn; };

int main(void) {
    struct test_case tests[] = {
        {"gdal_basics",       test_gdal_basics},
        {"geos_intersection", test_geos_intersection},
        {"proj_transform",    test_proj_transform},
    };
    int n = sizeof(tests) / sizeof(tests[0]);
    int failed = 0;

    for (int i = 0; i < n; i++) {
        printf("[RUN ] %s\n", tests[i].name);
        int rc = tests[i].fn();
        printf(rc == 0 ? "[PASS] %s\n" : "[FAIL] %s\n", tests[i].name);
        if (rc != 0) failed++;
    }

    if (failed == 0) {
        printf("All tests passed\n");
        return 0;
    }
    fprintf(stderr, "%d/%d tests failed\n", failed, n);
    return 1;
}
