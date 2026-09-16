print('Loading stringi package')
library(stringi)
print('... stringi package loaded successfully.') 

test_1 <- function() {
    "value='%d'" %s$% 3
    "value='%d'" %s$% 1:3
    "%s='%d'" %s$% list("value", 3)
    "%s='%d'" %s$% list("value", 1:3)
    "%s='%d'" %s$% list(c("a", "b", "c"), 1)
    "%s='%d'" %s$% list(c("a", "b", "c"), 1:3)
}

test_2 <- function() {
    x <- c("abcd", "\u00DF\u00B5\U0001F970", "abcdef")
    cat("[%6s]" %s$% x, sep="\n")  # width used, not the number of bytes
}

test_3 <- function() {
    'a' %stri<% 'b'
    c('a', 'b', 'c') %stri>=% 'b'
}

test_4 <- function() {
    e1 <- c("a", "b", "c")
    e2 <- c("b", "c", "d")
    e1 %s+% e2
    e1 %stri+% e2
}

test_5 <-function() {
    c('abc', '123', 'xy') %s+% letters[1:6]
    'ID_' %s+% 1:5
}

print('Running test 1')
test_1()
print('Running test 2')
test_2()
print('Running test 3')
test_3()
print('Running test 4')
test_4()
print('Running test 5')
test_5()
