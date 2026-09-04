// IMPORTS ---------------------------------------------------------------------

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{Some}
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import site/document.{type Document}
import site/page.{type Author, type Meta, Meta, Stylesheet}
import site/ui/djot
import tom

// META ------------------------------------------------------------------------

pub fn meta(slug: String, documents: Dict(String, Document)) -> Meta {
  let assert Ok(document) = dict.get(documents, "blog/" <> slug)
    as "document must exist for slug"

  let assert Some(frontmatter) = document.frontmatter
    as "document must have frontmatter"

  let assert Ok(toml) = tom.parse(frontmatter)
    as "frontmatter must be valid TOML"

  let assert Ok(title) = tom.get_string(toml, ["title"])
    as "frontmatter must have a title"

  let assert Ok(description) = tom.get_string(toml, ["description"])
    as "frontmatter must have a description"

  let assert Ok(author) =
    tom.get_array(toml, ["author"])
    |> result.map(list.filter_map(_, tom.as_string))
    |> result.map(list.filter_map(_, page.author))
    as "frontmatter must have an author array"

  Meta(
    title:,
    description:,
    author:,
    head: [
      Stylesheet(href: "/css/page/post.css"),
    ],
    content: ["blog/" <> slug],
  )
}

// VIEW ------------------------------------------------------------------------

pub fn view(meta: Meta, documents: Dict(String, Document)) -> Element(_) {
  let assert [post, ..] = meta.content
  let assert Ok(document) = dict.get(documents, post)

  page.view_empty_layout([
    view_hero(meta),
    page.view_navbar(),
    html.div([attribute.id("page-article")], {
      list.map(document.content.content, djot.block)
    }),
  ])
}

fn view_hero(meta: Meta) -> Element(_) {
  html.header([attribute.class("hero")], [
    view_hero_flowers(),
    html.div([attribute.class("inner")], [
      html.p([attribute.class("kicker")], [
        html.text("Blog"),
      ]),
      html.h1([attribute.class("title")], [
        html.text(meta.title),
      ]),
      html.p([attribute.class("subtitle")], [
        html.text(meta.description),
      ]),
      view_hero_byline(meta.author),
    ]),
  ])
}

fn view_hero_flowers() -> Element(_) {
  let left = "/img/flowers/library-of-congress-VFTxZaIsDAs-unsplash.png"
  let right =
    "/img/flowers/the-new-york-public-library-T-CMZ8gYLTw-unsplash.png"

  element.fragment([
    html.img([
      attribute.class("flower"),
      attribute.styles([
        #("left", "calc(clamp(0%, 10vw, 10%) * -2)"),
        #("bottom", "calc(clamp(0%, 10vw, 10%) * -2)"),
        #("rotate", "30deg"),
      ]),
      attribute.src(left),
    ]),

    html.img([
      attribute.class("flower"),
      attribute.styles([
        #("left", "calc(55% + clamp(0%, 15vw, 10%) * 2)"),
        #("bottom", "calc(clamp(5%, 15vw, 15%) * -3)"),
        #("rotate", "-45deg"),
      ]),
      attribute.src(right),
    ]),
  ])
}

fn view_hero_byline(authors: List(Author)) -> Element(_) {
  html.div([attribute.class("byline")], [
    html.ul(
      [],
      list.map(authors, fn(author) {
        html.li([], [
          html.img([
            attribute.src(author.img),
            attribute.alt(author.name),
          ]),
          html.div([attribute.class("details")], [
            html.p([], [html.text(author.name)]),
            html.a([attribute.href(author.url.1)], [html.text(author.url.0)]),
          ]),
        ])
      }),
    ),
  ])
}
