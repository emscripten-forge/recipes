library(S7)

Point <- new_class("Point", properties = list(x = class_numeric, y = class_numeric))
p <- Point(x = 1, y = 2)
stopifnot(S7_inherits(p, Point))
print(p)
