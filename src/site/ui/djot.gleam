// IMPORTS ---------------------------------------------------------------------

import contour
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import jot.{
  type Container, type Inline, BlockQuote, BulletList, Code, Codeblock, Delete,
  Div, Emphasis, Footnote, Heading, Image, Insert, Linebreak, Link, Mark,
  MathDisplay, MathInline, NonBreakingSpace, OrderedList, Paragraph, RawBlock,
  Reference, Span, Strong, Subscript, Superscript, Symbol, Text, ThematicBreak,
  Url,
}
import lustre/attribute.{type Attribute, attribute}
import lustre/element.{type Element}
import lustre/element/html
import site/ui/actions
import site/ui/figure

// VIEW ------------------------------------------------------------------------

pub fn block(element: Container) -> Element(_) {
  case element {
    ThematicBreak -> html.hr([])

    Paragraph(attributes:, content:) ->
      html.p(to_attributes(attributes), list.map(content, inline))

    Heading(attributes:, level:, content:) -> {
      case level {
        1 -> html.h1(to_attributes(attributes), list.map(content, inline))
        2 -> html.h2(to_attributes(attributes), list.map(content, inline))
        3 -> html.h3(to_attributes(attributes), list.map(content, inline))
        4 -> html.h4(to_attributes(attributes), list.map(content, inline))
        5 -> html.h5(to_attributes(attributes), list.map(content, inline))
        6 -> html.h6(to_attributes(attributes), list.map(content, inline))
        _ -> html.div(to_attributes(attributes), list.map(content, inline))
      }
    }

    Codeblock(attributes:, language:, content:) -> {
      html.div([attribute.class("snippet"), ..to_attributes(attributes)], [
        case language {
          Some("gleam") ->
            html.pre([attribute.data("lang", "gleam")], [
              element.unsafe_raw_html("", "code", [], contour.to_html(content)),
            ])

          Some("terminal") | Some("discord") ->
            html.pre([], [
              element.unsafe_raw_html("", "output", [], content),
            ])

          Some(_) ->
            html.pre([], [
              element.unsafe_raw_html("", "code", [], content),
            ])

          None -> element.unsafe_raw_html("", "pre", [], content)
        },
      ])
    }

    RawBlock(content:) -> element.unsafe_raw_html("", "!--", [], content)

    BulletList(items:, ..) ->
      html.ul([], {
        list.map(items, fn(item) {
          case item {
            [Paragraph(content:, ..)] -> html.li([], list.map(content, inline))
            _ -> html.li([], list.map(item, block))
          }
        })
      })

    OrderedList(items:, ..) ->
      html.ol([], {
        list.map(items, fn(item) {
          case item {
            [Paragraph(content:, ..)] -> html.li([], list.map(content, inline))
            _ -> html.li([], list.map(item, block))
          }
        })
      })

    BlockQuote(attributes:, items:) ->
      html.blockquote(to_attributes(attributes), list.map(items, block))

    Div(class:, attributes:, items:) ->
      case class, items {
        Some("figure"), [content, ..caption] ->
          figure.view(
            to_attributes(attributes),
            block(content),
            list.map(caption, block),
          )

        Some("actions"), [RawBlock(content:)] -> actions.from_raw_block(content)

        Some("actions"), [Codeblock(language: Some("=toml"), content:, ..)] ->
          actions.from_raw_block(content)

        _, _ -> html.div(to_attributes(attributes), list.map(items, block))
      }
  }
}

pub fn inline(element: Inline) -> Element(_) {
  case element {
    Linebreak -> html.br([])

    NonBreakingSpace -> html.text(" ")

    Text(string) -> html.text(string)

    Link(attributes: _, content: _, destination: Reference(_)) -> html.text("")

    Link(attributes:, content:, destination: Url(href)) ->
      html.a(
        [attribute.href(href), ..to_attributes(attributes)],
        list.map(content, inline),
      )

    Image(attributes: _, content: _, destination: Reference(_)) -> html.text("")

    Image(attributes:, content: _, destination: Url(src)) ->
      html.img([attribute.src(src), ..to_attributes(attributes)])

    Span(attributes:, content:) ->
      html.span(to_attributes(attributes), list.map(content, inline))

    Emphasis(content:) -> html.em([], list.map(content, inline))

    Strong(content:) -> html.strong([], list.map(content, inline))

    Delete(content:) -> html.del([], list.map(content, inline))

    Insert(content:) -> html.ins([], list.map(content, inline))

    Mark(content:) -> html.mark([], list.map(content, inline))

    Footnote(..) -> element.text("")

    Code(content:) -> html.code([], [html.text(content)])

    MathInline(..) | MathDisplay(..) -> html.text("")

    Superscript(content:) -> html.sup([], list.map(content, inline))

    Subscript(content:) -> html.sub([], list.map(content, inline))

    Symbol(content:) -> html.text(content)
  }
}

// UTILS -----------------------------------------------------------------------

fn to_attributes(attributes: Dict(String, String)) -> List(Attribute(_)) {
  dict.fold(attributes, [], fn(attributes, name, value) {
    [attribute(name, value), ..attributes]
  })
}
