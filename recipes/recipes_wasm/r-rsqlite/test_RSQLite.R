print('Loading RSQLite package')
library(RSQLite)
print('... RSQLite package loaded successfully')

test_1 <- function() {
    db <- dbConnect(SQLite(), ":memory:")
    dbWriteTable(db, "mtcars", mtcars)
    tbl <- dbReadTable(db, "mtcars")
    stopifnot(nrow(tbl) == nrow(mtcars))
    print(head(tbl))
    dbDisconnect(db)
}

print("Running test_1")
test_1()
