
library(reticulate)



func <- function() {

    import("os")

    print("we are here")

    # add 2+2 via python
    print(py_eval("2 + 2"))


    np <- import("numpy")
    print(np$ones(c(2L, 2L)))


  

}

func()

print("collecting garbage")
gc <- import("gc")
gc$collect()

print("done collecting garbage")