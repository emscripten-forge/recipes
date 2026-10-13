library(maps)

# Test 1: Load state map and calculate areas
m_state <- map("state", fill = TRUE, plot = FALSE)
total_area <- suppressWarnings(area.map(m_state))
nd_area <- suppressWarnings(area.map(m_state, "North Dakota"))
sd_area <- suppressWarnings(area.map(m_state, "South Dakota"))
cat("Test 1: State areas (sq miles)\n")
cat("  Total US:", round(total_area, 2), "\n")
cat("  North Dakota:", round(nd_area, 2), "\n")
cat("  South Dakota:", round(sd_area, 2), "\n\n")

# Test 2: Load county data and verify structure
m_county <- map('county', fill = TRUE, plot = FALSE)
num_counties <- length(unique(m_county$names))
cat("Test 2: County data\n")
cat("  Number of counties:", num_counties, "\n")
cat("  First 3 counties:", paste(head(unique(m_county$names), 3), collapse=", "), "\n\n")

# Test 3: Load Iowa counties and verify
m_iowa <- map('county', 'iowa', fill = TRUE, plot = FALSE)
iowa_counties <- unique(m_iowa$names)
cat("Test 3: Iowa counties\n")
cat("  Number of Iowa counties:", length(iowa_counties), "\n")
cat("  Sample counties:", paste(head(iowa_counties, 3), collapse=", "), "\n\n")
