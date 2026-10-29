// IMPORTS ---------------------------------------------------------------------

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import gleam/time/calendar.{type Date}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import site/document.{type Document}
import site/page.{type Author, type Meta, Meta, Stylesheet}
import tom

// TYPES -----------------------------------------------------------------------

type Post {
  Post(title: String, description: String, created: Date, author: List(Author))
}

// META ------------------------------------------------------------------------

pub const meta: Meta =
  Meta(
    title: "Blog",
    description: "Blog posts and articles written by the Lustre core team.",
    author: [page.hayleigh],
    head: [
      Stylesheet(href: "/css/page/blog.css"),
    ],
    content: [],
  )

// VIEW ------------------------------------------------------------------------

pub fn view(documents: Dict(String, Document)) -> Element(_) {
  let posts =
    dict.fold(documents, [], fn(acc, key, document) {
      case key {
        "/blog/" <> _ | "blog/" <> _ -> {
          let assert Some(frontmatter) = document.frontmatter
            as "document must have frontmatter"

          let assert Ok(toml) = tom.parse(frontmatter)
            as "frontmatter must be valid TOML"

          let assert Ok(title) = tom.get_string(toml, ["title"])
            as "frontmatter must have a title"

          let assert Ok(description) = tom.get_string(toml, ["description"])
            as "frontmatter must have a description"

          let assert Ok(created) = tom.get_date(toml, ["created"])

          let assert Ok(author) =
            tom.get_array(toml, ["author"])
            |> result.map(list.filter_map(_, tom.as_string))
            |> result.map(list.filter_map(_, page.author))
            as "frontmatter must have an author array"

          [#(key, Post(title:, description:, created:, author:)), ..acc]
        }

        _ -> acc
      }
    })

  page.view_empty_layout([
    page.view_navbar(),
    html.div([attribute.class("layout section"), attribute.id("posts")], [
      html.ul([], {
        posts
        |> list.sort(fn(a, b) {
          calendar.naive_date_compare(b.1.created, a.1.created)
        })
        |> list.index_map(fn(post, index) {
          view_post(post.0, post.1, index == 0)
        })
      }),
    ]),
  ])
}

fn view_post(route: String, post: Post, featured: Bool) -> Element(a) {
  html.li([attribute.classes([#("stamp", featured)])], [
    html.a([attribute.href(route)], [
      html.h2([], [html.text(post.title)]),
      html.p([attribute.class("date")], [view_post_date(post.created)]),
      html.p([], [html.text(post.description)]),
      html.p([attribute.class("authors")], [
        post.author
        |> list.map(fn(author) { author.name })
        |> string.join(", ")
        |> html.text,
      ]),
    ]),
  ])
}

fn view_post_date(created: Date) -> Element(a) {
  let day = string.pad_start(int.to_string(created.day), 2, "0")
  let month = case created.month {
    calendar.January -> "01"
    calendar.February -> "02"
    calendar.March -> "03"
    calendar.April -> "04"
    calendar.May -> "05"
    calendar.June -> "06"
    calendar.July -> "07"
    calendar.August -> "08"
    calendar.September -> "09"
    calendar.October -> "10"
    calendar.November -> "11"
    calendar.December -> "12"
  }

  html.time([], [
    html.text(day <> "/" <> month <> "/" <> int.to_string(created.year)),
  ])
}
