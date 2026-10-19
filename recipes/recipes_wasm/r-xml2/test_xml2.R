print('Loading xml2 package')
library(xml2)
print('... xml2 package loaded successfully')

test_1 <- function() {
    x <- read_xml("<x><y>1</y><y>2</y></x>")
    stopifnot(inherits(x, "xml_document"))
    ys <- xml_find_all(x, ".//y")
    stopifnot(length(ys) == 2L)
    stopifnot(identical(xml_text(ys), c("1", "2")))
}

test_2 <- function() {
    x <- read_xml("<root a='1'><child>hi</child></root>")
    stopifnot(identical(xml_attr(x, "a"), "1"))
    stopifnot(identical(xml_name(xml_child(x)), "child"))
    stopifnot(identical(xml_text(xml_child(x)), "hi"))
}

test_3 <- function() {
    doc <- read_html("<html><body><p>hello</p></body></html>")
    stopifnot(inherits(doc, "xml_document"))
    p <- xml_find_first(doc, ".//p")
    stopifnot(identical(xml_text(p), "hello"))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
