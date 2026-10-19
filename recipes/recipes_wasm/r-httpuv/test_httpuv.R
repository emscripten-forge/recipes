library(httpuv)

assert_identical <- function(actual, expected, label = "") {
  if (!identical(actual, expected)) {
    stop(
      if (nzchar(label)) paste0(label, ": ") else "",
      "expected ", paste(deparse(expected), collapse = ""),
      " but got ", paste(deparse(actual), collapse = ""),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

test_1 <- function() {
  # Smoke: package loads and core exports exist
  stopifnot(
    is.function(encodeURI),
    is.function(encodeURIComponent),
    is.function(decodeURI),
    is.function(decodeURIComponent),
    is.function(startServer),
    is.function(service),
    is.function(listServers)
  )
  TRUE
}

test_2 <- function() {
  # URI encode/decode (pure R; no channel)
  utf8_str <- "abc \ue5 \u4e2d\r\n"
  utf8_enc <- "abc%20%C3%A5%20%E4%B8%AD%0D%0A"
  reserved <- ",/?:@"
  reserved_enc <- "%2C%2F%3F%3A%40"

  assert_identical(encodeURI(utf8_str), utf8_enc, "encodeURI utf8")
  assert_identical(encodeURIComponent(utf8_str), utf8_enc, "encodeURIComponent utf8")
  assert_identical(decodeURIComponent(utf8_enc), utf8_str, "decodeURIComponent utf8")

  assert_identical(encodeURI(reserved), reserved, "encodeURI reserved")
  assert_identical(encodeURIComponent(reserved), reserved_enc, "encodeURIComponent reserved")

  # Shiny/DT nested query keys
  assert_identical(decodeURIComponent("columns%5B0%5D"), "columns[0]", "DT key")

  assert_identical(
    encodeURIComponent(c("a b", "x/y")),
    c("a%20b", "x%2Fy"),
    "vector encode"
  )
  TRUE
}

test_3 <- function() {
  # ipFamily is a simplified check in the browser build
  assert_identical(ipFamily("127.0.0.1"), 4L)
  assert_identical(ipFamily("0.0.0.0"), 4L)
  assert_identical(ipFamily("::1"), 6L)
  assert_identical(ipFamily("fe80::1"), 6L)
  assert_identical(ipFamily("localhost"), -1L)
  TRUE
}

test_4 <- function() {
  # Virtual server lifecycle (no real bind / no service worker)
  stopAllServers()
  assert_identical(length(listServers()), 0L)

  app <- list(
    call = function(req) {
      list(
        status = 200L,
        headers = list("Content-Type" = "text/plain"),
        body = charToRaw("ok")
      )
    }
  )

  s <- startServer("127.0.0.1", 0, app, quiet = TRUE)
  on.exit(stopAllServers(), add = TRUE)

  assert_identical(length(listServers()), 1L)
  stopifnot(isTRUE(s$isRunning()))
  assert_identical(s$getHost(), "127.0.0.1")
  assert_identical(s$getPort(), 0)

  # service() is a no-op retained for Shiny compatibility
  stopifnot(isTRUE(service(0)))

  stopServer(s)
  assert_identical(length(listServers()), 0L)
  TRUE
}

test_5 <- function() {
  # Pipe servers are unsupported in the browser build
  err <- tryCatch(
    startPipeServer("unused", 0, list(call = function(req) NULL)),
    error = function(e) e
  )
  stopifnot(inherits(err, "error"))
  stopifnot(grepl("Pipe servers are not supported", conditionMessage(err), fixed = TRUE))
  TRUE
}

test_6 <- function() {
  # Rook call path without the JS channel
  wrapper <- httpuv:::AppWrapper$new(list(
    call = function(req) {
      list(
        status = 200L,
        headers = list("Content-Type" = "text/plain"),
        body = charToRaw(paste0(req$PATH_INFO, "?", req$QUERY_STRING))
      )
    }
  ))

  got <- NULL
  req <- list(
    PATH_INFO = "/ping",
    QUERY_STRING = "a=1",
    REQUEST_METHOD = "GET",
    .bodyData = NULL
  )
  wrapper$call(req, function(resp) {
    got <<- resp
  })

  stopifnot(!is.null(got))
  assert_identical(got$status, 200L)
  assert_identical(rawToChar(got$body), "/ping?a=1")
  TRUE
}

test_7 <- function() {
  # Message → Rook env (internal; still no service worker)
  msg <- list(
    uuid = "u-1",
    method = "GET",
    url = "http://127.0.0.1:8080/shiny/session/abc?foo=bar",
    headers = list(`content-type` = "text/plain", `x-test` = "1"),
    body = as.list(charToRaw("hi"))
  )
  req <- httpuv:::httpuv_build_req(msg)
  on.exit({
    if (!is.null(req$.bodyData)) close(req$.bodyData)
  }, add = TRUE)

  assert_identical(req$UUID, "u-1")
  assert_identical(req$REQUEST_METHOD, "GET")
  assert_identical(req$QUERY_STRING, "foo=bar")
  assert_identical(req$HTTP_CONTENT_TYPE, "text/plain")
  assert_identical(req$HTTP_X_TEST, "1")
  assert_identical(req$CONTENT_LENGTH, "2")
  stopifnot(grepl("shiny", req$SCRIPT_NAME, fixed = TRUE))
  TRUE
}

test_8 <- function() {
  # Response formatting used before channel write
  resp <- httpuv:::httpuv_format_tcp_response(list(
    status = 200L,
    headers = list("Content-Type" = "application/octet-stream"),
    body = as.raw(c(1, 2, 3, 4))
  ))
  assert_identical(resp$status, 200L)
  assert_identical(resp$body$httpuvRaw, "base64")
  stopifnot(is.character(resp$body$data), nzchar(resp$body$data))

  # MIME helper used by static serving
  assert_identical(httpuv:::httpuv_guess_mime_type("x.js"), "application/javascript")
  assert_identical(httpuv:::httpuv_guess_mime_type("x.html"), "text/html")
  assert_identical(httpuv:::httpuv_guess_mime_type("x.bin"), "application/octet-stream")
  TRUE
}

test_9 <- function() {
  # Static path objects + in-process static serve
  dir <- tempfile("httpuv-static-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  writeLines("<html>ok</html>", file.path(dir, "index.html"))

  sp <- staticPath(dir)
  stopifnot(inherits(sp, "staticPath"))

  paths <- httpuv:::normalizeStaticPaths(c("/" = dir))
  stopifnot(identical(names(paths), "/"))

  wrapper <- httpuv:::AppWrapper$new(list(
    call = function(req) list(status = 404L, headers = list(), body = charToRaw("nope")),
    staticPaths = c("/" = dir)
  ))

  req <- list(PATH_INFO = "/", REQUEST_METHOD = "GET")
  static_resp <- httpuv:::httpuv_try_serve_static(wrapper, req)
  stopifnot(!is.null(static_resp))
  assert_identical(static_resp$status, 200L)
  stopifnot(grepl("ok", rawToChar(static_resp$body), fixed = TRUE))
  TRUE
}

test_10 <- function() {
  # Push API with no active server should not crash
  ok <- httpuv_push_http_request(list(
    uuid = "missing",
    method = "GET",
    url = "http://127.0.0.1/",
    headers = list(),
    body = list()
  ))
  assert_identical(ok, FALSE)
  TRUE
}

cat("Running test_1\n"); test_1()
cat("Running test_2\n"); test_2()
cat("Running test_3\n"); test_3()
cat("Running test_4\n"); test_4()
cat("Running test_5\n"); test_5()
cat("Running test_6\n"); test_6()
cat("Running test_7\n"); test_7()
cat("Running test_8\n"); test_8()
cat("Running test_9\n"); test_9()
cat("Running test_10\n"); test_10()