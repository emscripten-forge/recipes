#include <stdio.h>
#include <string.h>

#include <nanoarrow/nanoarrow.h>
#include <nanoarrow/nanoarrow_ipc.h>

int main(void) {
    struct ArrowSchema schema;
    struct ArrowError error;

    ArrowSchemaInit(&schema);
    if (ArrowSchemaSetType(&schema, NANOARROW_TYPE_INT32) != NANOARROW_OK) {
        fprintf(stderr, "ArrowSchemaSetType() failed\n");
        return 1;
    }

    if (schema.format == NULL || strcmp(schema.format, "i") != 0) {
        fprintf(stderr, "Unexpected Arrow format: %s\n", schema.format == NULL ? "<null>" : schema.format);
        ArrowSchemaRelease(&schema);
        return 1;
    }

    if (ArrowNanoarrowVersion() == NULL || ArrowNanoarrowVersion()[0] == '\0') {
        fprintf(stderr, "ArrowNanoarrowVersion() returned an invalid value\n");
        ArrowSchemaRelease(&schema);
        return 1;
    }

    if (ArrowIpcCheckRuntime(&error) != NANOARROW_OK) {
        fprintf(stderr, "ArrowIpcCheckRuntime() failed: %s\n", error.message);
        ArrowSchemaRelease(&schema);
        return 1;
    }

    if (ArrowIpcGetZstdDecompressionFunction() == NULL) {
        fprintf(stderr, "ArrowIpcGetZstdDecompressionFunction() returned NULL\n");
        ArrowSchemaRelease(&schema);
        return 1;
    }

    if (ArrowIpcGetLZ4DecompressionFunction() == NULL) {
        fprintf(stderr, "ArrowIpcGetLZ4DecompressionFunction() returned NULL\n");
        ArrowSchemaRelease(&schema);
        return 1;
    }

    ArrowSchemaRelease(&schema);
    puts("nanoarrow smoke test passed");
    return 0;
}