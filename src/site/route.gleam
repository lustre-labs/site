// IMPORTS ---------------------------------------------------------------------

import filepath
import gleam/dict.{type Dict}
import gleam/string
import lustre/element.{type Element}
import site/document.{type Document}
import site/page.{type Meta}
import site/page/blog/post
import site/page/index

// TYPES -----------------------------------------------------------------------

pub type Route {
  Index
  BlogPost(slug: String)
}

// CONSTRUCTORS ----------------------------------------------------------------

pub fn from_path(path: String) -> Result(Route, Nil) {
  let segments = case path {
    "/" <> rest -> filepath.split(rest)
    _ -> filepath.split(path)
  }

  case segments {
    [] | ["index"] -> Ok(Index)
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
    BlogPost(slug:) -> post.view(post.meta(slug, documents), documents)
  }
}

pub fn to_filename(route: Route) -> String {
  case route {
    Index -> "index.html"
    BlogPost(slug) -> "blog/" <> slug <> ".html"
  }
}

pub fn to_meta(route: Route, documents: Dict(String, Document)) -> Meta {
  case route {
    Index -> index.meta
    BlogPost(slug:) -> post.meta(slug, documents)
  }
}
