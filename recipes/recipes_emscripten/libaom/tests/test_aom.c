#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "aom/aom.h"
#include "aom/aom_encoder.h"
#include "aom/aom_decoder.h"
#include "aom/aomcx.h"
#include "aom/aomdx.h"

int main(void) {
    /* Check version string */
    const char *version = aom_codec_version_str();
    printf("libaom version: %s\n", version ? version : "NULL");
    if (!version || strlen(version) == 0) {
        printf("FAIL: empty version string\n");
        return 1;
    }

    /* Test encoder init/destroy */
    {
        aom_codec_ctx_t ctx;
        aom_codec_enc_cfg_t cfg;
        aom_codec_err_t res;

        res = aom_codec_enc_config_default(aom_codec_av1_cx(), &cfg, 0);
        if (res != AOM_CODEC_OK) {
            printf("FAIL: enc_config_default returned %d\n", (int)res);
            return 1;
        }

        res = aom_codec_enc_init(&ctx, aom_codec_av1_cx(), &cfg, 0);
        if (res != AOM_CODEC_OK) {
            printf("FAIL: enc_init: %s\n", aom_codec_error(&ctx));
            return 1;
        }
        aom_codec_destroy(&ctx);
        printf("Encoder init/destroy: OK\n");
    }

    /* Test decoder init/destroy */
    {
        aom_codec_ctx_t ctx;
        aom_codec_err_t res;

        res = aom_codec_dec_init(&ctx, aom_codec_av1_dx(), NULL, 0);
        if (res != AOM_CODEC_OK) {
            printf("FAIL: dec_init: %s\n", aom_codec_error(&ctx));
            return 1;
        }
        aom_codec_destroy(&ctx);
        printf("Decoder init/destroy: OK\n");
    }

    printf("All tests passed\n");
    return 0;
}
