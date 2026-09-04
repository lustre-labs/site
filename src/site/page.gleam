// IMPORTS ---------------------------------------------------------------------

import gleam/list
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import site/ui/icon

// TYPES -----------------------------------------------------------------------

pub type Meta {
  Meta(
    title: String,
    description: String,
    author: List(Author),
    head: List(HeadElement),
    content: List(String),
  )
}

pub type Author {
  Author(name: String, img: String, url: #(String, String))
}

pub type HeadElement {
  InlineScript(source: String)
  InlineStylesheet(css: String)
  Script(src: String)
  Stylesheet(href: String)
}

// CONSTANTS -------------------------------------------------------------------

pub const hayleigh = Author(
  name: "Hayleigh Thompson",
  img: "/img/team/hayleigh.png",
  url: #("hayleigh.dev", "https://hayleigh.dev"),
)

pub const rebecca = Author(
  name: "Rebecca Reusch",
  img: "/img/team/rebecca.png",
  url: #("becca.monster", "https://becca.monster"),
)

// CONSTRUCTORS ----------------------------------------------------------------

pub fn author(name: String) -> Result(Author, Nil) {
  case name {
    "hayleigh" -> Ok(hayleigh)
    "rebecca" -> Ok(rebecca)
    _ -> Error(Nil)
  }
}

// CONVERSIONS -----------------------------------------------------------------

const google_fonts = "https://fonts.googleapis.com/css2"
  <> "?family=Neuton:ital,wght@0,200;0,300;0,400;0,700;0,800;1,400"
  <> "&family=Space+Mono:ital,wght@0,400;0,700;1,400;1,700"
  <> "&family=Space+Grotesk:wght@300..700"
  <> "&family=Caveat:wght@400..700"
  <> "&display=swap"

pub fn to_html(
  meta: Meta,
  head: List(Element(_)),
  content: Element(_),
) -> String {
  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),

      html.title([], meta.title),

      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.googleapis.com"),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.gstatic.com"),
        attribute.crossorigin(""),
      ]),

      html.link([attribute.rel("stylesheet"), attribute.href(google_fonts)]),
      html.link([attribute.rel("stylesheet"), attribute.href("/css/_base.css")]),

      element.fragment(
        list.map(meta.head, fn(element) {
          case element {
            InlineScript(source:) ->
              html.script(
                [attribute.type_("module"), attribute("defer", "")],
                source,
              )
            InlineStylesheet(css:) -> html.style([], css)
            Script(src:) -> html.script([attribute.src(src)], "")
            Stylesheet(href:) ->
              html.link([
                attribute.rel("stylesheet"),
                attribute.href(href),
              ])
          }
        }),
      ),

      element.fragment(head),
    ]),

    html.body([], [
      content,
    ]),
  ])
  |> element.to_document_string
}

// VIEW ------------------------------------------------------------------------

///
///
pub fn view_empty_layout(content: List(Element(_))) -> Element(_) {
  element.fragment([
    view_github_sponsor_banner(),
    element.fragment(content),
    view_footer(),
  ])
}

fn view_github_sponsor_banner() -> Element(_) {
  html.aside(
    [attribute.id("layout-sponsor-banner"), attribute.data("mode", "pro")],
    [
      html.p([], [
        html.text("Please consider supporting the project through "),
        html.a(
          [attribute.href("https://github.com/sponsors/hayleigh-dot-dev/")],
          [html.text("GitHub Sponsors")],
        ),
        html.text("."),
      ]),
    ],
  )
}

pub fn view_navbar() -> Element(_) {
  html.header([attribute.id("layout-navbar")], [
    html.div([attribute.class("inner")], [
      html.a([attribute.href("/")], [html.text("Lustre")]),
      html.nav([attribute.class("nav")], [
        html.a([attribute.href("/docs/overview")], [
          html.text("Docs"),
          icon.external_link([]),
        ]),
        html.a([attribute.href("/blog")], [
          html.text("Blog"),
        ]),
        html.a([attribute.href("/changelog")], [
          html.text("Changelog"),
        ]),
      ]),
    ]),
  ])
}

fn view_footer() -> Element(_) {
  html.footer([attribute.id("layout-footer"), attribute.data("mode", "brand")], [
    html.div([attribute.class("inner")], [
      // view_footer_nav(),
      html.aside([attribute.class("footer-byline")], [
        html.p([], [
          html.text("Made with 💕 by Lustre Labs"),
        ]),
        html.p([], [
          html.text(
            "contact@lustre.build – Copyright © 2025 Lustre Labs BV. All
      rights reserved.",
          ),
        ]),
      ]),
    ]),
  ])
}
// TODO: bring this back once we have more things to put in the footer.
//
// fn view_footer_nav() -> Element(_) {
//   html.nav([attribute.class("footer-nav")], [
//     view_footer_nav_column("Lustre", [
//       #("https://github.com/lustre-labs/lustre", "GitHub"),
//       #("https://hexdocs.pm/lustre/index.html", "API reference"),
//       #("/changelog", "Changelog"),
//     ]),
//   ])
// }

// fn view_footer_nav_column(
//   title: String,
//   links: List(#(String, String)),
// ) -> Element(_) {
//   html.div([attribute.class("footer-nav-column")], [
//     html.p([], [html.text(title)]),
//     element.fragment(
//       list.map(links, fn(link) {
//         html.a([attribute.href(link.0)], [html.text(link.1)])
//       }),
//     ),
//   ])
// }
