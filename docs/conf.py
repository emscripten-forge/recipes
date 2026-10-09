import shutil
from pathlib import Path

project = 'Emscripten-forge'
author = 'Emscripten-forge maintainers'
copyright = '2026'

extensions = [
    "myst_parser",
    "ablog",
]

exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# Blog: any .md file in blog/posts is a post, ordered by the date in its {post} directive
blog_post_pattern = "blog/posts/*"
blog_title = f"{project} blog"
blog_authors = {
    "derthorsten": ("Dr. Thorsten Beier", "https://github.com/DerThorsten"),
    "wolfv": ("Wolf Vollprecht", "https://prefix.dev"),
}
post_date_format = "%Y-%m-%d"
post_date_format_short = "%Y-%m-%d"

_book_sidebar = ["navbar-logo.html", "icon-links.html", "search-button-field.html", "sbt-sidebar-nav.html"]
_blog_widgets = ["ablog/categories.html", "ablog/authors.html", "ablog/archives.html"]

html_css_files = ["custom.css"]
html_static_path = ['assets']
html_sidebars = {
    "blog/posts/*": _book_sidebar[:3] + ["ablog/postcard.html"] + _book_sidebar[3:],
    "blog/index": _book_sidebar + _blog_widgets,
    "blog/archive": _book_sidebar + _blog_widgets,
    "blog/archive/**": _book_sidebar + _blog_widgets,
}
html_theme = "sphinx_book_theme"
html_theme_options = {
    "logo": {
        "alt_text": "Emscripten-forge logo",
        "image_dark": "assets/icon.svg",
        "image_light": "assets/icon.svg",
        "text": project,
    },
    "navbar_persistent": [],
    "repository_url": "https://github.com/emscripten-forge/recipes",
    "use_repository_button": True,
}
html_title = project


def _copy_qtapp(app, exception):
    """Copy docs/qtapp to the same place in the HTML output, unchanged."""
    if exception is None and app.builder.format == "html":
        shutil.copytree(Path(app.srcdir) / "qtapp", Path(app.outdir) / "qtapp", dirs_exist_ok=True)


def setup(app):
    app.connect("build-finished", _copy_qtapp)
