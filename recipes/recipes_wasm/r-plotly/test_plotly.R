print('Loading plotly package')
library(plotly)
print('... plotly package loaded successfully')

test_1 <- function() {


    plot_ly(x = c(1, 2, 3, 4), y = c(1, 4, 9, 16)) %>%
      layout(title = TeX("\\text{Some mathjax: }\\alpha+\\beta x")) %>%
      config(mathjax = "cdn")
}

test_2 <- function() {


    plot_ly() %>% add_data(economics) %>% add_trace(x = ~date, y = ~pce)
}

test_3 <- function() {


    df <- data.frame(
      x = c(1, 2, 2, 1, 1, 2),
      y = c(1, 2, 2, 1, 1, 2),
      z = c(1, 1, 2, 2, 3, 3)
    )
    plot_ly(df) %>%
      add_markers(x = 1.5, y = 1.5) %>%
      add_markers(x = ~x, y = ~y, frame = ~z)

    # it's a good idea to remove smooth transitions when there is
    # no relationship between objects in each view
    plot_ly(mtcars, x = ~wt, y = ~mpg, frame = ~cyl) %>%
      animation_opts(transition = 0)

    # works the same way with ggplotly
    if (interactive()) {
      p <- ggplot(txhousing, aes(month, median)) +
        geom_line(aes(group = year), alpha = 0.3) +
        geom_smooth() +
        geom_line(aes(frame = year, ids = month), color = "red") +
        facet_wrap(~ city)
 
      ggplotly(p, width = 1200, height = 900) %>%
        animation_opts(1000)
    }

  
    #' # for more, see https://plotly.com/r/animating-views.html
}

test_4 <- function() {


    trace <- list(x = 1, y = 1)
    obj <- list(data = list(trace), layout = list(title = "my plot"))
    as_widget(obj)
}

test_5 <- function() {


    p <- plot_ly(mtcars, x = ~wt, y = ~mpg, color = ~cyl)

    # pass any colorbar attribute -- 
    # https://plotly.com/r/reference/#scatter-marker-colorbar
    colorbar(p, len = 0.5)

    # Expand the limits of the colorbar
    colorbar(p, limits = c(0, 20))
    # values outside the colorbar limits are considered "missing"
    colorbar(p, limits = c(5, 6))

    # also works on colorbars generated via a z value
    corr <- cor(diamonds[vapply(diamonds, is.numeric, logical(1))])
    plot_ly(x = rownames(corr), y = colnames(corr), z = corr) %>%
     add_heatmap() %>%
     colorbar(limits = c(-1, 1))
}

test_6 <- function() {


    # remove the plotly logo and 2D lasso option from modebar
    config(plot_ly(), displaylogo = FALSE, modeBarButtonsToRemove = list("lasso2d"))

    # enable mathjax
    # see more examples at https://plotly.com/r/LaTeX/
    plot_ly(x = c(1, 2, 3, 4), y = c(1, 4, 9, 16)) %>%
      layout(title = TeX("\\text{Some mathjax: }\\alpha+\\beta x")) %>%
      config(mathjax = "cdn")

    # change the language used to render date axes and on-graph text 
    # (e.g., modebar buttons)
    today <- Sys.Date()
    x <- seq.Date(today, today + 360, by = "day")
    p <- plot_ly(x = x, y = rnorm(length(x))) %>%
      add_lines()

    # japanese
    config(p, locale = "ja")
    # german
    config(p, locale = "de")
    # spanish
    config(p, locale = "es")
    # chinese
    config(p, locale = "zh-CN")
}

test_7 <- function() {


    # note the insertion of new rows with missing values 
    group2NA(mtcars, "vs", "cyl")

    # need to group lines by city somehow!
    plot_ly(txhousing, x = ~date, y = ~median) %>% add_lines()

    # instead of using group_by(), you could use group2NA()
    tx <- group2NA(txhousing, "city")
    plot_ly(tx, x = ~date, y = ~median) %>% add_lines()

    # add_lines() will ensure paths are sorted by x, but this is equivalent
    tx <- group2NA(txhousing, "city", ordered = "date")
    plot_ly(tx, x = ~date, y = ~median) %>% add_paths()
}

test_8 <- function() {


    p <- plot_ly(mtcars, x = ~wt, y = ~cyl, color = ~cyl)
    hide_colorbar(p)
}

test_9 <- function() {


    p <- plot_ly(mtcars, x = ~wt, y = ~cyl, color = ~factor(cyl))
    hide_legend(p)
}

test_10 <- function() {


    # These examples are designed to show you how to highlight/brush a *single*
    # view. For examples of multiple linked views, see `demo(package = "plotly")` 

    d <- highlight_key(txhousing, ~city)
    p <- ggplot(d, aes(date, median, group = city)) + geom_line()
    gg <- ggplotly(p, tooltip = "city") 
    highlight(gg, dynamic = TRUE)

    # supply custom colors to the brush 
    cols <- toRGB(RColorBrewer::brewer.pal(3, "Dark2"), 0.5)
    highlight(gg, on = "plotly_hover", color = cols, dynamic = TRUE)

    # Use attrs_selected() for complete control over the selection appearance
    # note any relevant colors you specify here should override the color argument
    s <- attrs_selected(
      showlegend = TRUE,
      mode = "lines+markers",
      marker = list(symbol = "x")
    )

    highlight(layout(gg, showlegend = TRUE), selected = s)
}


print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

print("Running test_4")
test_4()

print("Running test_5")
test_5()

print("Running test_6")
test_6()

print("Running test_7")
test_7()

print("Running test_8")
test_8()

print("Running test_9")
test_9()

print("Running test_10")
test_10()
