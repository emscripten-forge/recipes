library(shiny)

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
  # Package loads + core exports
  stopifnot(
    is.function(reactive),
    is.function(isolate),
    is.function(testServer),
    is.function(shinyApp),
    is.function(parseQueryString),
    is.function(fluidPage)
  )
  TRUE
}

test_2 <- function() {
  # UI builders return HTML/tag objects (no server needed)
  ui <- fluidPage(
    titlePanel("wasm"),
    textInput("name", "Name", value = "Ada"),
    actionButton("go", "Go"),
    verbatimTextOutput("out")
  )
  stopifnot(inherits(ui, "shiny.tag.list") || inherits(ui, "shiny.tag"))

  btn <- actionButton("go", "Go")
  stopifnot(inherits(btn, "shiny.tag"))
  assert_identical(btn$attribs$id, "go")

  ns <- NS("mod")
  assert_identical(ns("x"), "mod-x")
  TRUE
}

test_3 <- function() {
  # Query parsing (incl. nested DT-style keys)
  q <- parseQueryString("?foo=1&bar=b%20a%20r")
  assert_identical(q$foo, "1")
  assert_identical(q$bar, "b a r")

  nested <- parseQueryString(
    "?columns[0][data]=mpg&columns[0][search][value]=&draw=1",
    nested = TRUE
  )
  stopifnot(is.list(nested$columns))
  assert_identical(nested$columns[["0"]][["data"]], "mpg")
  assert_identical(nested$draw, "1")
  TRUE
}

test_4 <- function() {
  # Basic reactivity without a browser
  # (flushReact is unexported)
  x <- reactiveVal(1)
  y <- reactive(x() * 2)
  assert_identical(isolate(y()), 2)

  x(5)
  shiny:::flushReact()
  assert_identical(isolate(y()), 10)
  TRUE
}

test_5 <- function() {
  # Server logic via testServer (MockShinySession under the hood)
  server <- function(input, output, session) {
    rv <- reactiveValues(x = 0)
    observe({
      rv$x <- input$n * 2
    })
    output$txt <- renderText({
      paste0("Value: ", rv$x)
    })
  }

  testServer(server, {
    session$setInputs(n = 1)
    assert_identical(rv$x, 2)
    assert_identical(output$txt, "Value: 2")

    session$setInputs(n = 3)
    assert_identical(rv$x, 6)
    assert_identical(output$txt, "Value: 6")
  })
  TRUE
}

test_6 <- function() {
  # eventReactive + modules-style namespacing in testServer
  server <- function(input, output, session) {
    result <- eventReactive(input$go, {
      input$a + input$b
    }, ignoreNULL = FALSE)

    output$sum <- renderText(result())
  }

  testServer(server, {
    session$setInputs(a = 2, b = 5, go = 1)
    assert_identical(result(), 7)
    assert_identical(output$sum, "7")

    session$setInputs(a = 10)
    # unchanged until go fires again
    assert_identical(result(), 7)

    session$setInputs(go = 2)
    assert_identical(result(), 15)
  })
  TRUE
}

test_7 <- function() {
  # shinyApp builds an app object; do NOT call runApp()
  app <- shinyApp(
    ui = fluidPage(textInput("x", "x"), textOutput("y")),
    server = function(input, output, session) {
      output$y <- renderText(input$x)
    }
  )
  stopifnot(inherits(app, "shiny.appobj"))
  stopifnot(is.function(app$httpHandler) || is.function(app$ui) || !is.null(app$serverFuncSource))
  TRUE
}

test_8 <- function() {
  # MockShinySession: invalidateLater / elapse without httpuv I/O
  session <- MockShinySession$new()
  i <- 0L
  isolate({
    observe({
      invalidateLater(10, session)
      i <<- i + 1L
    })
  })
  session$flushReact()
  assert_identical(i, 1L)
  session$elapse(10)
  assert_identical(i, 2L)
  session$close()
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