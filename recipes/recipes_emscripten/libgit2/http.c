/*
 * libgit2 HTTP transport implementation using emscripten.
 * Based on the marvellous https://github.com/petersalomonsen/wasm-git
 */
#include "common.h"
#include "http.h"
#include "httpclient.h"
#include "smart.h"

#include "emscripten.h"

#define DEFAULT_BUFSIZE 65536

static const char* upload_pack_ls_service_url = "/info/refs?service=git-upload-pack";
static const char* upload_pack_service_url = "/git-upload-pack";
static const char* receive_pack_ls_service_url = "/info/refs?service=git-receive-pack";
static const char* receive_pack_service_url = "/git-receive-pack";

typedef struct {
    git_smart_subtransport_stream parent;
    git_http_method service_method;
    const char* service_url;
    int connection_index;
} emforge_http_stream;

typedef struct {
    git_smart_subtransport parent;
    transport_smart* owner;
} emforge_http_subtransport;

/* JavaScript functions */

EM_JS(int, emforge_js_http_connect, (const char* url, const char* method, size_t buf_size), {
    const url_js = UTF8ToString(url);
    const method_js = UTF8ToString(method);

    try {
        const xhr = new XMLHttpRequest();
        xhr.open(method_js, url_js, false);
        xhr.responseType = "arraybuffer";
        if (method_js == "POST") {
            const content_type_header = url_js.includes("git-upload-pack") ?
                "application/x-git-upload-pack-request" :
                "application/x-git-receive-pack-request";
            xhr.setRequestHeader("Content-Type", content_type_header);
        }

        let index = 0;
        if (!Module["emforge_js_http_cache"]) {
            Module["emforge_js_http_cache"] = { "next_index": index };
        } else {
            index = Module["emforge_js_http_cache"]["next_index"]++;
        }

        Module["emforge_js_http_cache"][index] = {
            xhr,
            resultbufferpointer: 0,
            buf_size
        };

        if (method_js == "GET") {
            xhr.send();
        }

        return index;
    } catch (err) {
        console.error(err);
        return -1;
    }
});

EM_JS(size_t, emforge_js_http_read, (int conn_index, size_t buf_size, char* buffer), {
    try {
        const connection = Module["emforge_js_http_cache"][conn_index];

        if (connection.content) {
            connection.xhr.send(connection.content.buffer);
            connection.content = null;
        }

        let bytes_read = connection.xhr.response.byteLength - connection.resultbufferpointer;
        if (bytes_read > buf_size) {
            bytes_read = buf_size;
        }

        const responseChunk = new Uint8Array(
            connection.xhr.response,
            connection.resultbufferpointer,
            bytes_read
        );
        writeArrayToMemory(responseChunk, buffer);
        connection.resultbufferpointer += bytes_read;
        return bytes_read
    } catch (err) {
        console.error(err);
        return -1;
    }
});

EM_JS(size_t, emforge_js_http_write, (int conn_index, size_t len, char* buffer), {
    try {
        const connection = Module["emforge_js_http_cache"][conn_index];
        const buffer_js = new Uint8Array(HEAPU8.buffer, buffer, len).slice(0);
        if (!connection.content) {
            connection.content = buffer_js;
        } else {
            const content = new Uint8Array(connection.content.length + buffer_js.length);
            content.set(connection.content);
            content.set(buffer_js, connection.content.length);
            connection.content = content;
        }
        return 0;
    } catch (err) {
        console.error(err);
        return -1;
    }
});

EM_JS(int, emforge_js_http_has_convert_url, (void), {
    return Module["libgit2_convert_url"] ? 1 : 0;
});

EM_JS(const char*, emforge_js_http_call_convert_url, (const char* url), {
    /* Assume emforge_js_http_has_convert_url has been called and returned 1. */
    const url_js = UTF8ToString(url);
    const converted_js = Module["libgit2_convert_url"](url_js);
    return stringToNewUTF8(converted_js);
});

/* C functions */

/* From libgit2 httpclient.c */
static const char* name_for_method(git_http_method method)
{
    switch (method) {
      case GIT_HTTP_METHOD_GET:
        return "GET";
      case GIT_HTTP_METHOD_POST:
        return "POST";
      case GIT_HTTP_METHOD_CONNECT:
        return "CONNECT";
    }
    return NULL;
}

static int emforge_http_stream_read(
    git_smart_subtransport_stream* s,
    char* buffer,
    size_t buf_size,
    size_t* bytes_read)
{
    emforge_http_stream* stream = (emforge_http_stream*)s;
    size_t bytes;

    if (stream->connection_index == -1) {
        const char* method = name_for_method(stream->service_method);
        int connection_index = emforge_js_http_connect(stream->service_url, method, DEFAULT_BUFSIZE);
        if (connection_index < 0) {
            git_error_set(GIT_ERROR_HTTP, "error making http(s) connection");
            return -1;
        }
        stream->connection_index = connection_index;
    }

    bytes = emforge_js_http_read(stream->connection_index, buf_size, buffer);
    if (bytes < 0) {
        git_error_set(GIT_ERROR_HTTP, "error reading from http(s) connection");
        return -1;
    }

    *bytes_read = bytes;
    return 0;
}

static int emforge_http_stream_write(
    git_smart_subtransport_stream* s,
    const char* buffer,
    size_t len)
{
    emforge_http_stream* stream = (emforge_http_stream*)s;
    int error;

    if (stream->connection_index == -1) {
        const char* method = name_for_method(stream->service_method);
        int connection_index = emforge_js_http_connect(stream->service_url, method, DEFAULT_BUFSIZE);
        if (connection_index < 0) {
            git_error_set(GIT_ERROR_HTTP, "error making http(s) connection");
            return -1;
        }
        stream->connection_index = connection_index;
    }

    error = emforge_js_http_write(stream->connection_index, len, buffer);
    if (error < 0) {
        git_error_set(GIT_ERROR_HTTP, "error writing to http(s) connection");
        return -1;
    }

    return 0;
}

static void emforge_http_stream_free(git_smart_subtransport_stream* s)
{
    emforge_http_stream* stream = GIT_CONTAINER_OF(s, emforge_http_stream, parent);
    git__free(s);
}

static int emforge_http_action(
    git_smart_subtransport_stream** out,
    git_smart_subtransport* t,
    const char* url,
    git_smart_service_t action)
{
    emforge_http_subtransport* transport = GIT_CONTAINER_OF(t, emforge_http_subtransport, parent);
    emforge_http_stream* stream;
    git_str buf = GIT_STR_INIT;
    git_http_method method;
    const char* converted_url = NULL;

    GIT_ASSERT_ARG(out);
    GIT_ASSERT_ARG(t);

    *out = NULL;

    stream = git__calloc(sizeof(emforge_http_stream), 1);
    GIT_ERROR_CHECK_ALLOC(stream);

    switch (action) {
        case GIT_SERVICE_UPLOADPACK_LS:
            method = GIT_HTTP_METHOD_GET;
            git_str_printf(&buf, "%s%s", url, upload_pack_ls_service_url);
            break;
        case GIT_SERVICE_UPLOADPACK:
            method = GIT_HTTP_METHOD_POST;
            git_str_printf(&buf, "%s%s", url, upload_pack_service_url);
            break;
        case GIT_SERVICE_RECEIVEPACK_LS:
            method = GIT_HTTP_METHOD_GET;
            git_str_printf(&buf, "%s%s", url, receive_pack_ls_service_url);
            break;
        case GIT_SERVICE_RECEIVEPACK:
            method = GIT_HTTP_METHOD_POST;
            git_str_printf(&buf, "%s%s", url, receive_pack_service_url);
            break;
        default:
            git_error_set(GIT_ERROR_HTTP, "unrecognised http(s) action");
            return -1;
            break;
    }
    stream->service_url = git_str_cstr(&buf);

    if (emforge_js_http_has_convert_url()) {
        /*
         * If Module["emforge_js_http_call_convert_url"] is defined then call it to convert the URL.
         * Typically this is used to specify a CORS proxy, and it is done this way so that clients
         * of this library such as git2cpp can define their own conversion functions, perhaps based
         * on environment variables, rather than require libgit2 to be modified and rebuilt when a
         * different method of conversion needs to be used.
         */
        converted_url = emforge_js_http_call_convert_url(stream->service_url);
        free(stream->service_url);
        stream->service_url = strdup(converted_url);
        free(converted_url);
    }

    stream->service_method = method;
    stream->connection_index = -1;  /* No connection yet */

    stream->parent.subtransport = &transport->parent;
    stream->parent.read = emforge_http_stream_read;
    if (stream->service_method != GIT_HTTP_METHOD_GET) {
        stream->parent.write = emforge_http_stream_write;
    }
    stream->parent.free = emforge_http_stream_free;

    *out = (git_smart_subtransport_stream*)stream;
    return 0;
}

static int emforge_http_close(git_smart_subtransport* t)
{
    emforge_http_subtransport* transport = GIT_CONTAINER_OF(t, emforge_http_subtransport, parent);
    return 0;
}

static void emforge_http_free(git_smart_subtransport* t)
{
    emforge_http_subtransport* transport = GIT_CONTAINER_OF(t, emforge_http_subtransport, parent);
    emforge_http_close(t);
    git__free(transport);
}

int git_smart_subtransport_http(git_smart_subtransport** out, git_transport* owner, void* param)
{
    emforge_http_subtransport* transport;

    GIT_UNUSED(param);
    GIT_ASSERT_ARG(out);

    transport = git__calloc(sizeof(emforge_http_subtransport), 1);
    GIT_ERROR_CHECK_ALLOC(transport);

    transport->owner = (transport_smart*)owner;
    transport->parent.action = emforge_http_action;
    transport->parent.close = emforge_http_close;
    transport->parent.free = emforge_http_free;

    *out = (git_smart_subtransport*)transport;
    return 0;
}
