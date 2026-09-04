// IMPORTS ---------------------------------------------------------------------

import frontmatter.{Extracted}
import gleam/option.{type Option}
import jot

// TYPES -----------------------------------------------------------------------

pub type Document {
  Document(frontmatter: Option(String), content: jot.Document)
}

// CONSTRUCTORS ----------------------------------------------------------------

pub fn parse(source: String) -> Document {
  let Extracted(frontmatter:, content:) = frontmatter.extract(source)
  let content = jot.parse(content)

  Document(frontmatter:, content:)
}
