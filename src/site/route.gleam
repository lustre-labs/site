// IMPORTS ---------------------------------------------------------------------

import filepath
import gleam/bool
import gleam/dict.{type Dict}
import gleam/string
import lustre/element.{type Element}
import site/document.{type Document}
import site/page.{type Meta}
import site/page/blog/index as blog
import site/page/blog/post
import site/page/index

// TYPES -----------------------------------------------------------------------

pub type Route {
  Index
  BlogIndex
  BlogPost(slug: String)
}

// CONSTANTS -------------------------------------------------------------------

pub const static_routes = [
  Index,
  BlogIndex,
]

// CONSTRUCTORS ----------------------------------------------------------------

pub fn from_path(path: String) -> Result(Route, Nil) {
  // files with a '#' symbol are fragments and not routes.
  use <- bool.guard(string.contains(path, "#"), Error(Nil))

  let segments = case path {
    "/" <> rest -> filepath.split(rest)
    _ -> filepath.split(path)
  }

  case segments {
    [] | ["index"] -> Ok(Index)
    ["blog"] -> Ok(BlogIndex)
    ["blog", ..slug] -> Ok(BlogPost(slug: string.join(slug, "/")))
    _ -> Error(Nil)
  }
}

// CONVERSIONS -----------------------------------------------------------------

pub fn to_content(
  route: Route,
  documents: Dict(String, Document),
) -> Element(_) {
  case route {
    Index -> index.view(documents)
    BlogIndex -> blog.view(documents)
    BlogPost(slug:) -> post.view(post.meta(slug, documents), documents)
  }
}

pub fn to_filename(route: Route) -> String {
  case route {
    Index -> "index.html"
    BlogIndex -> "blog/index.html"
    BlogPost(slug) -> "blog/" <> slug <> "/index.html"
  }
}

pub fn to_meta(route: Route, documents: Dict(String, Document)) -> Meta {
  case route {
    Index -> index.meta
    BlogIndex -> blog.meta
    BlogPost(slug:) -> post.meta(slug, documents)
  }
}
