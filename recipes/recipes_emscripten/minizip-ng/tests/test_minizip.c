#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <mz.h>
#include <mz_zip.h>
#include <mz_zip_rw.h>
#include <mz_strm.h>
#include <mz_strm_mem.h>

static const char *test_data = "Hello from minizip-ng! This is test content for the zip archive.";
static const char *test_filename = "test_file.txt";

static int test_create_zip(void) {
    void *mem_stream = NULL;
    void *writer = NULL;
    mz_zip_file file_info;
    int32_t err;

    printf("  Creating in-memory zip...\n");

    /* Create memory stream */
    mz_stream_mem_create(&mem_stream);
    mz_stream_mem_set_grow_size(mem_stream, 128 * 1024);
    err = mz_stream_open(mem_stream, NULL, MZ_OPEN_MODE_CREATE);
    if (err != MZ_OK) {
        printf("  FAIL: mz_stream_open failed with error %d\n", err);
        return 1;
    }

    /* Create zip writer */
    mz_zip_writer_create(&writer);
    err = mz_zip_writer_open(writer, mem_stream, 0);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_writer_open failed with error %d\n", err);
        return 1;
    }

    /* Set file info */
    memset(&file_info, 0, sizeof(file_info));
    file_info.version_madeby = MZ_VERSION_MADEBY;
    file_info.flag = MZ_ZIP_FLAG_UTF8;
    file_info.compression_method = MZ_COMPRESS_METHOD_DEFLATE;
    file_info.filename = test_filename;
    file_info.filename_size = (uint16_t)strlen(test_filename);

    printf("  Adding file '%s'...\n", test_filename);
    err = mz_zip_writer_entry_open(writer, &file_info);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_writer_entry_open failed with error %d\n", err);
        return 1;
    }

    err = mz_zip_writer_entry_write(writer, test_data, (int32_t)strlen(test_data));
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_writer_entry_write failed with error %d\n", err);
        return 1;
    }

    err = mz_zip_writer_entry_close(writer);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_writer_entry_close failed with error %d\n", err);
        return 1;
    }

    err = mz_zip_writer_close(writer);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_writer_close failed with error %d\n", err);
        return 1;
    }

    /* Read back from memory stream */
    printf("  Reading back zip...\n");

    void *reader = NULL;
    mz_zip_reader_create(&reader);

    /* Seek memory stream to beginning */
    mz_stream_seek(mem_stream, 0, MZ_SEEK_SET);

    err = mz_zip_reader_open(reader, mem_stream);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_reader_open failed with error %d\n", err);
        return 1;
    }

    /* Open the first entry */
    err = mz_zip_reader_goto_first_entry(reader);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_reader_goto_first_entry failed with error %d\n", err);
        return 1;
    }

    /* Get file info */
    mz_zip_file *read_info = NULL;
    err = mz_zip_reader_entry_get_info(reader, &read_info);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_reader_entry_get_info failed with error %d\n", err);
        return 1;
    }

    printf("  Found file: %s (size: %llu)\n", read_info->filename, read_info->uncompressed_size);

    /* Verify filename */
    if (strcmp(read_info->filename, test_filename) != 0) {
        printf("  FAIL: expected filename '%s', got '%s'\n", test_filename, read_info->filename);
        return 1;
    }

    /* Open entry for reading */
    err = mz_zip_reader_entry_open(reader);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_reader_entry_open failed with error %d\n", err);
        return 1;
    }

    /* Read content */
    char read_buffer[256] = {0};
    int32_t bytes_read = mz_zip_reader_entry_read(reader, read_buffer, (int32_t)sizeof(read_buffer) - 1);
    if (bytes_read < 0) {
        printf("  FAIL: mz_zip_reader_entry_read failed with error %d\n", bytes_read);
        return 1;
    }
    read_buffer[bytes_read] = '\0';

    printf("  Read %d bytes: '%s'\n", bytes_read, read_buffer);

    /* Verify content */
    if (strcmp(read_buffer, test_data) != 0) {
        printf("  FAIL: data mismatch. Expected '%s', got '%s'\n", test_data, read_buffer);
        return 1;
    }

    err = mz_zip_reader_entry_close(reader);
    if (err != MZ_OK) {
        printf("  FAIL: mz_zip_reader_entry_close failed with error %d\n", err);
        return 1;
    }

    err = mz_zip_reader_close(reader);
    mz_zip_reader_delete(&reader);

    /* Cleanup */
    mz_zip_writer_delete(&writer);
    mz_stream_mem_delete(&mem_stream);

    return 0;
}

static int test_compress_methods(void) {
    /* Verify compression method constants are defined */
    printf("  Compression methods available:\n");
    printf("    DEFLATE: %d\n", MZ_COMPRESS_METHOD_DEFLATE);
    printf("    BZIP2:   %d\n", MZ_COMPRESS_METHOD_BZIP2);
    printf("    LZMA:    %d\n", MZ_COMPRESS_METHOD_LZMA);
    printf("    ZSTD:    %d\n", MZ_COMPRESS_METHOD_ZSTD);
    printf("    PPMD:    %d\n", MZ_COMPRESS_METHOD_PPMD);
    printf("    AES:     %d\n", MZ_COMPRESS_METHOD_AES);

    /* Basic existence check */
    if (MZ_COMPRESS_METHOD_DEFLATE != 8) {
        printf("  FAIL: DEFLATE method should be 8\n");
        return 1;
    }

    return 0;
}

int main(void) {
    int failures = 0;

    printf("minizip-ng tests\n");
    printf("================\n\n");

    printf("Test: Compression methods...\n");
    if (test_compress_methods() != 0) {
        printf("  FAILED\n\n");
        failures++;
    } else {
        printf("  PASSED\n\n");
    }

    printf("Test: Create and read zip...\n");
    if (test_create_zip() != 0) {
        printf("  FAILED\n\n");
        failures++;
    } else {
        printf("  PASSED\n\n");
    }

    if (failures == 0) {
        printf("All tests passed!\n");
        return 0;
    } else {
        printf("%d test(s) FAILED!\n", failures);
        return 1;
    }
}
