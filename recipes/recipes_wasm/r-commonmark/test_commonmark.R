library(commonmark)
md <- "## Test
An *example* text for the `commonmark` package."

# Convert to Latex
cat(markdown_latex(md))

# Convert to HTML
cat(markdown_html(md))

# Convert to HTML
cat(markdown_html(md))

# Convert back to (normalized) markdown
cat(markdown_commonmark(md))

# The markdown parse tree
cat(markdown_xml(md))