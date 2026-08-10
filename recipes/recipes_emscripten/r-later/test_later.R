library(later)

print("Wait 2 seconds...")
later::later(\() print("Done waiting!"), 2)