import os
import shutil
from pathlib import Path

project = 'Emscripten-forge'
author = 'Emscripten-forge maintainers'
copyright = '2026'

extensions = [
    "myst_parser",
    "ablog",
    "sphinxext.opengraph",
]

exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# Open Graph defaults
ogp_site_url = "https://emscripten-forge.org/"
ogp_site_name = project
ogp_image = "_static/og_image.png"
ogp_image_alt = "Emscripten-forge"
ogp_type = "website"
ogp_social_cards = {"enable": False}

_OGP_DEFAULT_DESCRIPTION = (
    "Conda packages and recipes for the emscripten-wasm32 and emscripten-wasm64 "
    "WebAssembly platforms."
)

# Per-page Open Graph overrides (MyST field lists conflict with ABlog's {post} directive)
_OGP_PAGE_META = {
    "blog/posts/r_shiny": {
        "og:type": "article",
        "og:image": "https://emscripten-forge.org/_static/og_image_r_shiny.png",
        "og:image:alt": "Emscripten-forge and Shiny",
        "og:description": (
            "Run fully static Shiny dashboards in the browser with emscripten-forge, "
            "and publish them to GitHub Pages with a single template repository."
        ),
    },
}
_OGP_PAGE_EXTRA_TAGS = {
    "blog/posts/r_shiny": [
        '<meta property="article:published_time" content="2026-10-09T00:00:00Z" />',
        '<meta property="article:author" content="Isabel Paredes" />',
        '<meta property="article:tag" content="r-lang" />',
    ],
}

# Blog: any .md file in blog/posts is a post, ordered by the date in its {post} directive
blog_post_pattern = "blog/posts/*"
blog_title = f"{project} blog"
blog_authors = {
    "derthorsten": ("Thorsten Beier", "https://github.com/DerThorsten"),
    "wolfv": ("Wolf Vollprecht", "https://prefix.dev"),
    "IsabelParedes": ("Isabel Paredes", "https://github.com/IsabelParedes/")
}
post_date_format = "%Y-%m-%d"
post_date_format_short = "%Y-%m-%d"

_book_sidebar = ["navbar-logo.html", "icon-links.html", "search-button-field.html", "sbt-sidebar-nav.html"]
_blog_widgets = ["ablog/categories.html", "ablog/authors.html", "ablog/archives.html"]

html_css_files = ["custom.css"]
html_js_files = []
if os.environ.get("DOCS_ANALYTICS"):
    # Privacy-friendly analytics by Plausible, only enabled for deployed builds
    html_js_files += [
        ("https://plausible.io/js/pa-bn73BBhX5to7i8j6XrXy2.js", {"async": "async"}),
        (None, {"body": "window.plausible=window.plausible||function(){(plausible.q=plausible.q||[]).push(arguments)},"
                        "plausible.init=plausible.init||function(i){plausible.o=i||{}};plausible.init()"}),
    ]
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
html_favicon = "assets/icon.svg"


def _copy_qtapp(app, exception):
    """Copy docs/qtapp to the same place in the HTML output, unchanged."""
    if exception is None and app.builder.format == "html":
        shutil.copytree(Path(app.srcdir) / "qtapp", Path(app.outdir) / "qtapp", dirs_exist_ok=True)


def _ogp_set_page_meta(app, pagename, templatename, context, doctree):
    """Feed sphinxext-opengraph before it runs (priority < 500)."""
    meta = dict(context.get("meta") or {})
    if pagename in _OGP_PAGE_META:
        meta.update(_OGP_PAGE_META[pagename])
    meta.setdefault("og:description", _OGP_DEFAULT_DESCRIPTION)
    context["meta"] = meta


def _ogp_append_extra_tags(app, pagename, templatename, context, doctree):
    """Append article:* tags after sphinxext-opengraph (which only emits og:*)."""
    extra = _OGP_PAGE_EXTRA_TAGS.get(pagename)
    if extra:
        context["metatags"] = context.get("metatags", "") + "\n".join(extra) + "\n"


def setup(app):
    app.connect("html-page-context", _ogp_set_page_meta, priority=400)
    app.connect("html-page-context", _ogp_append_extra_tags, priority=600)
    app.connect("build-finished", _copy_qtapp)
