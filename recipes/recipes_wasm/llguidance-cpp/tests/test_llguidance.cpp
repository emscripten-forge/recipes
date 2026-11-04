#include <cstdio>
#include <cstdint>
#include <cstring>
#include <vector>
#include <algorithm>
#include <cassert>

#include "llguidance.h"

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------
static int failures = 0;

#define CHECK(cond) \
    do { \
        if (!(cond)) { \
            std::fprintf(stderr, "FAIL: %s (line %d)\n", #cond, __LINE__); \
            ++failures; \
        } \
    } while (false)

// ---------------------------------------------------------------------------
// Byte tokenizer: each byte is a token, plus EOS at index 256
// Adapted from upstream c_sample/c_sample.cpp
// ---------------------------------------------------------------------------

// Thread-safe tokenize callback: each byte = one token
static size_t byte_tokenize_callback(const void * /*user_data*/,
                                      const uint8_t *bytes,
                                      size_t bytes_len,
                                      uint32_t *output_tokens,
                                      size_t output_tokens_len) {
    if (output_tokens_len > 0) {
        size_t n = std::min(output_tokens_len, bytes_len);
        for (size_t i = 0; i < n; i++) {
            output_tokens[i] = static_cast<uint32_t>(bytes[i]);
        }
    }
    return bytes_len;
}

// Create a tokenizer with 256 byte tokens + 1 EOS token (257 total)
static LlgTokenizer *create_byte_tokenizer() {
    // Build token data
    std::vector<uint32_t> token_lens(257);
    std::vector<uint8_t> token_bytes;

    // 256 single-byte tokens
    for (size_t i = 0; i < 256; i++) {
        token_lens[i] = 1;
        token_bytes.push_back(static_cast<uint8_t>(i));
    }

    // EOS token: "<EOS>"
    const char *eos_str = "<EOS>";
    size_t eos_len = std::strlen(eos_str);
    token_lens[256] = static_cast<uint32_t>(eos_len);
    for (size_t i = 0; i < eos_len; i++) {
        token_bytes.push_back(static_cast<uint8_t>(eos_str[i]));
    }

    LlgTokenizerInit tok_init = {};
    tok_init.vocab_size = 257;
    tok_init.tok_eos = 256;
    tok_init.token_lens = token_lens.data();
    tok_init.token_bytes = token_bytes.data();
    tok_init.tokenize_assumes_string = false;
    tok_init.tokenize_fn = byte_tokenize_callback;
    tok_init.tokenize_user_data = nullptr;

    char error_buf[256] = {};
    LlgTokenizer *tok = llg_new_tokenizer(&tok_init, error_buf, sizeof(error_buf));
    if (!tok) {
        std::fprintf(stderr, "FAIL: llg_new_tokenizer returned null: %s\n", error_buf);
    }
    return tok;
}

// ---------------------------------------------------------------------------
// Test: llg_get_version
// ---------------------------------------------------------------------------
static void test_get_version() {
    std::printf("Testing llg_get_version...\n");
    const char *ver = llg_get_version();
    CHECK(ver != nullptr);
    CHECK(std::strlen(ver) > 0);
    std::printf("  Version: %s\n", ver);
    std::printf("  llg_get_version OK\n");
}

// ---------------------------------------------------------------------------
// Test: Create tokenizer
// ---------------------------------------------------------------------------
static LlgTokenizer *test_create_tokenizer() {
    std::printf("Testing tokenizer creation...\n");
    LlgTokenizer *tok = create_byte_tokenizer();
    CHECK(tok != nullptr);
    std::printf("  Tokenizer creation OK\n");
    return tok;
}

// ---------------------------------------------------------------------------
// Test: Tokenize bytes
// ---------------------------------------------------------------------------
static void test_tokenize_bytes(LlgTokenizer *tok) {
    std::printf("Testing llg_tokenize_bytes...\n");

    const char *input = "hello";
    size_t input_len = std::strlen(input);

    // First call to get required buffer size
    size_t n_tokens = llg_tokenize_bytes(tok,
        reinterpret_cast<const uint8_t *>(input), input_len,
        nullptr, 0);
    CHECK(n_tokens == input_len);  // byte tokenizer: one token per byte

    // Second call to get actual tokens
    std::vector<uint32_t> tokens(n_tokens);
    size_t n = llg_tokenize_bytes(tok,
        reinterpret_cast<const uint8_t *>(input), input_len,
        tokens.data(), n_tokens);
    CHECK(n == input_len);
    CHECK(tokens[0] == 'h');
    CHECK(tokens[4] == 'o');

    std::printf("  llg_tokenize_bytes OK\n");
}

// ---------------------------------------------------------------------------
// Test: Regex constraint
// ---------------------------------------------------------------------------
static void test_regex_constraint(LlgTokenizer *tok) {
    std::printf("Testing regex constraint...\n");

    LlgConstraintInit init;
    llg_constraint_init_set_defaults(&init, tok);
    init.log_stderr_level = 0;  // suppress warnings during test

    // Create constraint matching the regex "hello"
    LlgConstraint *cc = llg_new_constraint_regex(&init, "hello");
    CHECK(cc != nullptr);
    CHECK(llg_get_error(cc) == nullptr);

    // Compute mask for the first token
    LlgMaskResult mask_res;
    int32_t rc = llg_compute_mask(cc, &mask_res);
    CHECK(rc == 0);
    CHECK(!mask_res.is_stop);

    // Token 'h' (0x68 = 104) should be in the mask
    const uint32_t *mask = mask_res.sample_mask;
    CHECK(mask != nullptr);
    bool h_allowed = (mask['h' / 32] & (1u << ('h' % 32))) != 0;
    CHECK(h_allowed);

    // Commit 'h'
    LlgCommitResult commit_res;
    rc = llg_commit_token(cc, 'h', &commit_res);
    CHECK(rc == 0);
    CHECK(commit_res.n_tokens == 1);
    CHECK(commit_res.tokens[0] == 'h');

    // Commit remaining characters: 'e', 'l', 'l', 'o'
    for (char ch : {'e', 'l', 'l', 'o'}) {
        rc = llg_compute_mask(cc, &mask_res);
        CHECK(rc == 0);
        bool allowed = (mask_res.sample_mask[ch / 32] & (1u << (ch % 32))) != 0;
        CHECK(allowed);

        rc = llg_commit_token(cc, static_cast<uint32_t>(ch), &commit_res);
        CHECK(rc == 0);
    }

    // After "hello", should be stopped (EOS forced)
    rc = llg_compute_mask(cc, &mask_res);
    CHECK(rc == 0);
    CHECK(mask_res.is_stop);

    llg_free_constraint(cc);
    std::printf("  Regex constraint OK\n");
}

// ---------------------------------------------------------------------------
// Test: JSON schema constraint
// ---------------------------------------------------------------------------
static void test_json_constraint(LlgTokenizer *tok) {
    std::printf("Testing JSON schema constraint...\n");

    LlgConstraintInit init;
    llg_constraint_init_set_defaults(&init, tok);
    init.log_stderr_level = 0;

    // Simple JSON schema: {"type": "boolean"}
    const char *schema =
        "{\"type\": \"object\", \"properties\": "
        "{\"x\": {\"type\": \"boolean\"}}, "
        "\"required\": [\"x\"]}";

    LlgConstraint *cc = llg_new_constraint_json(&init, schema);
    CHECK(cc != nullptr);
    CHECK(llg_get_error(cc) == nullptr);

    llg_free_constraint(cc);
    std::printf("  JSON schema constraint OK\n");
}

// ---------------------------------------------------------------------------
// Test: Stop controller
// ---------------------------------------------------------------------------
static void test_stop_controller(LlgTokenizer *tok) {
    std::printf("Testing stop controller...\n");

    // Stop token: '<EOS>' which is token 256 in our byte tokenizer
    uint32_t stop_tokens[] = {256};
    char error_buf[256] = {};

    LlgStopController *sc = llg_new_stop_controller(
        tok, stop_tokens, 1, nullptr, error_buf, sizeof(error_buf));
    CHECK(sc != nullptr);
    CHECK(std::strlen(error_buf) == 0);

    // Commit a regular token (not stop)
    size_t output_len = 0;
    bool is_stopped = false;
    const char *result = llg_stop_commit_token(sc, 'h', &output_len, &is_stopped);
    CHECK(!is_stopped);

    // Commit the stop token
    result = llg_stop_commit_token(sc, 256, &output_len, &is_stopped);
    CHECK(is_stopped);

    llg_free_stop_controller(sc);
    std::printf("  Stop controller OK\n");
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
int main() {
    std::printf("==========================================\n");
    std::printf("llguidance C API tests\n");
    std::printf("==========================================\n\n");

    test_get_version();

    LlgTokenizer *tok = test_create_tokenizer();
    if (!tok) {
        std::fprintf(stderr, "Cannot continue: tokenizer creation failed\n");
        return 1;
    }

    test_tokenize_bytes(tok);
    test_regex_constraint(tok);
    test_json_constraint(tok);
    test_stop_controller(tok);

    llg_free_tokenizer(tok);

    std::printf("\n==========================================\n");
    if (failures == 0) {
        std::printf("All tests passed!\n");
    } else {
        std::fprintf(stderr, "%d test(s) FAILED\n", failures);
    }
    std::printf("==========================================\n");

    return failures > 0 ? 1 : 0;
}
