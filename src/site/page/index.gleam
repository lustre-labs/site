// IMPORTS ---------------------------------------------------------------------

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import site/document.{type Document}
import site/page.{Meta, Stylesheet}
import site/ui/actions
import site/ui/djot
import site/ui/icon

// META ------------------------------------------------------------------------

pub const meta = Meta(
  title: "Lustre, the universal framework.",
  description: "",
  author: [page.hayleigh],
  head: [
    Stylesheet(href: "/css/page/index.css"),
  ],
  content: [
    "index#highlights",
    "index#snippet",
  ],
)

// VIEW ------------------------------------------------------------------------

pub fn view(documents: Dict(String, Document)) -> Element(_) {
  page.view_empty_layout([
    view_hero(),
    view_stats(),
    page.view_navbar(),
    view_divider(),
    view_highlights(documents),
    view_snippet(documents),
    view_divider(),
    view_component_links(),
  ])
}

fn view_divider() -> Element(_) {
  html.div([attribute.class("divider")], [])
}

// HERO ------------------------------------------------------------------------

fn view_hero() -> Element(_) {
  html.section([attribute.class("hero")], [
    view_hero_flowers(),
    html.div([attribute.class("inner")], [
      view_hero_title(),
      view_hero_subtitle(),
      view_hero_cta(),
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

fn view_hero_title() -> Element(_) {
  html.h1([attribute.class("title")], [
    html.text("Frontend can still be "),
    html.span([attribute.class("highlight")], [html.text("joyful.")]),
    // html.text("."),
  ])
}

fn view_hero_subtitle() -> Element(_) {
  let chunks = [
    "Lustre is a straightforward library for building",
    "static HTML documents,",
    "single-page applications,",
    "web components,",
    "and interactive server components.",
  ]

  html.p([attribute.class("subtitle")], {
    use phrase, i <- list.index_map(chunks)
    let offset = attribute.style("--offset", int.to_string(i))

    string.split(phrase, " ")
    |> list.map(fn(word) {
      html.span([offset, attribute.class("transition-enter")], [
        html.text(word),
      ])
    })
    |> list.intersperse(html.text(" "))
    |> list.append([html.text(" ")])
    |> element.fragment
  })
}

fn view_hero_cta() -> Element(message) {
  html.div([attribute.class("cta")], [
    html.button(
      [attribute.class("transition-enter"), attribute.style("--offset", "5")],
      [
        html.text("Get started"),
        icon.book_text([]),
      ],
    ),
    html.a(
      [
        attribute.class("ghost transition-enter"),
        attribute.style("--offset", "6"),
        attribute.href("/blog/why-use-gleam"),
      ],
      [html.text("Why use Gleam?")],
    ),
  ])
}

// STATS -----------------------------------------------------------------------

fn view_stats() -> Element(_) {
  html.section([attribute.id("page-stats")], [
    html.ul([], [
      view_stat("280k+", "downloads"),
      view_stat("2.4k", "GitHub stars"),
      view_stat("16kB", "gzipped"),
      view_stat("90", "releases"),
    ]),
  ])
}

fn view_stat(value: String, label: String) -> Element(_) {
  html.li([], [
    html.span([attribute.class("value")], [html.text(value)]),
    html.span([], [html.text(label)]),
  ])
}

// COMPONENT LINKS -------------------------------------------------------------

fn view_component_links() -> Element(_) {
  html.section([attribute.id("page-components-links")], [
    actions.view([], [
      actions.view_action(
        "Why Web Components?",
        "Watch this talk from FOSDEM 2026.",
        "https://fosdem.org/2026/schedule/event/9MJ8LX-making-web-components-work/",
      ),
      actions.view_action(
        "Learn about server components",
        "Server components bring Lustre's reactivity to your backend.",
        "https://www.youtube.com/watch?v=TbCm-zR7qZ0",
      ),
    ]),
  ])
}

// HIGHLIGHTS ------------------------------------------------------------------

fn view_highlights(documents: Dict(String, Document)) -> Element(_) {
  let assert Ok(document) = dict.get(documents, "index#highlights")
    as "missing content for highlights section"

  html.section(
    [attribute.id("page-highlights")],
    list.map(document.content.content, djot.block),
  )
}

// SNIPPET ---------------------------------------------------------------------

fn view_snippet(documents: Dict(String, Document)) -> Element(_) {
  let assert Ok(document) = dict.get(documents, "index#snippet")
    as "missing content for snippet section"

  html.div([attribute.style("padding-inline", "calc(var(--size-gap) * 2)")], [
    html.section(
      [attribute.id("page-snippet")],
      list.map(document.content.content, djot.block),
    ),
  ])
}
