// IMPORTS ---------------------------------------------------------------------

import filepath
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import simplifile
import site/document.{type Document}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  Nil
}

// UTILS -----------------------------------------------------------------------

pub fn collect_content() -> Dict(String, Document) {
  let assert Ok(files) = simplifile.get_files("content")
  use content, path <- list.fold(files, dict.new())
  let assert Ok(document) = simplifile.read(path) |> result.map(document.parse)
  let assert "content/" <> name = filepath.strip_extension(path)

  dict.insert(content, name, document)
}
