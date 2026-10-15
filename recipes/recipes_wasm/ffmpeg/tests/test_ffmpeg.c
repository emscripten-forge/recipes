#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/log.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>

#include <stdio.h>
#include <string.h>

int main(void) {
    int failures = 0;

    // Set log level to quiet for clean test output
    av_log_set_level(AV_LOG_QUIET);

    // === Test 1: Library versions ===
    printf("=== FFmpeg Library Versions ===\n");
    printf("libavutil:    %s\n", av_version_info());
    printf("libavcodec:   %u.%u.%u\n",
           (unsigned)avcodec_version() >> 16,
           ((unsigned)avcodec_version() >> 8) & 0xFF,
           (unsigned)avcodec_version() & 0xFF);
    printf("libavformat:  %u.%u.%u\n",
           (unsigned)avformat_version() >> 16,
           ((unsigned)avformat_version() >> 8) & 0xFF,
           (unsigned)avformat_version() & 0xFF);
    printf("libswscale:   %u.%u.%u\n",
           (unsigned)swscale_version() >> 16,
           ((unsigned)swscale_version() >> 8) & 0xFF,
           (unsigned)swscale_version() & 0xFF);
    printf("libswresample:%u.%u.%u\n",
           (unsigned)swresample_version() >> 16,
           ((unsigned)swresample_version() >> 8) & 0xFF,
           (unsigned)swresample_version() & 0xFF);

    // Verify minimum versions
    if (avcodec_version() < 60 * 65536) {
        printf("FAIL: libavcodec version too old\n");
        failures++;
    } else {
        printf("PASS: libavcodec version check\n");
    }

    // === Test 2: AVCodec API — find a decoder ===
    const AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (codec) {
        printf("PASS: Found H.264 decoder: %s\n", codec->name);
    } else {
        printf("FAIL: Could not find H.264 decoder\n");
        failures++;
    }

    // === Test 3: AVCodec API — find an encoder ===
    codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    if (codec) {
        printf("PASS: Found H.264 encoder: %s\n", codec->name);
    } else {
        printf("INFO: H.264 encoder not available (expected without libx264)\n");
    }

    // === Test 4: AVFormat — muxer/demuxer iteration ===
    void *opaque = NULL;
    const AVOutputFormat *ofmt;
    int muxer_count = 0;
    while ((ofmt = av_muxer_iterate(&opaque))) {
        muxer_count++;
    }
    printf("PASS: Found %d muxers\n", muxer_count);
    if (muxer_count == 0) {
        printf("FAIL: No muxers found\n");
        failures++;
    }

    // === Test 5: SwsContext — basic allocation ===
    struct SwsContext *sws = sws_getContext(
        1920, 1080, AV_PIX_FMT_YUV420P,
        1280, 720, AV_PIX_FMT_RGB24,
        SWS_BILINEAR, NULL, NULL, NULL);
    if (sws) {
        printf("PASS: SwsContext created successfully\n");
        sws_freeContext(sws);
    } else {
        printf("FAIL: Could not create SwsContext\n");
        failures++;
    }

    // === Test 6: SwrContext — basic allocation ===
    SwrContext *swr = NULL;
    int ret = swr_alloc_set_opts2(&swr,
        &(AVChannelLayout)AV_CHANNEL_LAYOUT_STEREO, AV_SAMPLE_FMT_S16, 44100,
        &(AVChannelLayout)AV_CHANNEL_LAYOUT_STEREO, AV_SAMPLE_FMT_FLTP, 48000,
        0, NULL);
    if (ret >= 0 && swr) {
        ret = swr_init(swr);
        if (ret >= 0) {
            printf("PASS: SwrContext initialized successfully\n");
        } else {
            printf("FAIL: swr_init failed: %d\n", ret);
            failures++;
        }
        swr_free(&swr);
    } else {
        printf("FAIL: swr_alloc_set_opts2 failed: %d\n", ret);
        failures++;
    }

    // === Summary ===
    printf("\n=== Results ===\n");
    if (failures == 0) {
        printf("PASS: All FFmpeg API tests passed\n");
        return 0;
    } else {
        printf("FAIL: %d test(s) failed\n", failures);
        return 1;
    }
}
