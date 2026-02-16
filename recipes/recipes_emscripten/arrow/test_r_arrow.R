#!/usr/bin/env Rscript

# Test script for r-arrow package
cat("========================================\n")
cat("Testing r-arrow package\n")
cat("========================================\n\n")

# Test 1: Load the arrow library
cat("Test 1: Loading arrow library...\n")
tryCatch({
    library(arrow)
    cat("✓ Successfully loaded arrow library\n\n")
}, error = function(e) {
    cat("✗ Failed to load arrow library:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
})

# Test 2: Create a simple arrow table
cat("Test 2: Creating arrow table...\n")
tryCatch({
    df <- data.frame(
        x = 1:5,
        y = c("a", "b", "c", "d", "e"),
        z = c(1.1, 2.2, 3.3, 4.4, 5.5)
    )
    tbl <- arrow_table(df)
    cat("✓ Successfully created arrow table\n")
    cat("  Dimensions:", nrow(tbl), "rows x", ncol(tbl), "columns\n\n")
}, error = function(e) {
    cat("✗ Failed to create arrow table:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
})

# Test 3: Test basic arrow array operations
cat("Test 3: Creating and testing arrow arrays...\n")
tryCatch({
    arr <- Array$create(c(1, 2, 3, 4, 5))
    cat("✓ Successfully created arrow array\n")
    cat("  Length:", arr$length(), "\n")
    cat("  Type:", arr$type$ToString(), "\n\n")
}, error = function(e) {
    cat("✗ Failed to create arrow array:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
})

# Test 4: Test schema creation
cat("Test 4: Creating arrow schema...\n")
tryCatch({
    schema <- schema(
        x = int32(),
        y = utf8(),
        z = float64()
    )
    cat("✓ Successfully created arrow schema\n")
    cat("  Fields:", paste(names(schema), collapse = ", "), "\n\n")
}, error = function(e) {
    cat("✗ Failed to create arrow schema:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
})

# Test 5: Test RecordBatch creation
cat("Test 5: Creating RecordBatch...\n")
tryCatch({
    batch <- record_batch(
        x = 1:3,
        y = c("foo", "bar", "baz")
    )
    cat("✓ Successfully created RecordBatch\n")
    cat("  Rows:", batch$num_rows, "\n")
    cat("  Columns:", batch$num_columns, "\n\n")
}, error = function(e) {
    cat("✗ Failed to create RecordBatch:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
})

# Test 6: Test data type functions
cat("Test 6: Testing Arrow data types...\n")
tryCatch({
    types <- list(
        int8(), int16(), int32(), int64(),
        uint8(), uint16(), uint32(), uint64(),
        float32(), float64(),
        utf8(), boolean()
    )
    cat("✓ Successfully created Arrow data types\n")
    cat("  Tested", length(types), "data types\n\n")
}, error = function(e) {
    cat("✗ Failed to create data types:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
})

cat("========================================\n")
cat("All r-arrow tests passed! ✓\n")
cat("========================================\n")
quit(status = 0)
