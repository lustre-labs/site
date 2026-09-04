// IMPORTS ---------------------------------------------------------------------

import gleam/list
import gleam/result
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import tom

// ELEMENTS --------------------------------------------------------------------

///
/// 
pub fn view(
  attributes: List(Attribute(_)),
  children: List(Element(_)),
) -> Element(_) {
  html.div([attribute.class("actions"), ..attributes], children)
}

///
/// 
pub fn view_action(
  title: String,
  subtitle: String,
  href: String,
) -> Element(_) {
  html.a([attribute.href(href)], [
    html.p([attribute.class("title")], [html.text(title)]),
    html.p([attribute.class("subtitle")], [html.text(subtitle)]),
  ])
}

// 

///
/// 
pub fn from_raw_block(content: String) -> Element(_) {
  let assert Ok(toml) = tom.parse(content)
  let assert Ok(actions) =
    tom.get_array(toml, ["actions"])
    |> result.replace_error(Nil)
    |> result.map(
      list.map(_, fn(action) {
        let assert Ok(table) = tom.as_table(action)
        let assert Ok(title) = tom.get_string(table, ["title"])
        let assert Ok(subtitle) = tom.get_string(table, ["subtitle"])
        let assert Ok(href) = tom.get_string(table, ["link"])

        view_action(title, subtitle, href)
      }),
    )

  view([], actions)
}
