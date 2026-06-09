library(RSQLite)

db <- dbConnect(SQLite(), ":memory:")

dbWriteTable(db, "mtcars", mtcars)

dbReadTable(db, "mtcars")

dbDisconnect(db)