// IMPORTS ---------------------------------------------------------------------

import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

// ELEMENTS --------------------------------------------------------------------

pub fn view(
  attributes: List(Attribute(_)),
  content: Element(_),
  caption: List(Element(_)),
) -> Element(_) {
  html.figure(attributes, [
    content,
    case caption {
      [] -> element.none()
      caption -> html.figcaption([], caption)
    },
  ])
}
