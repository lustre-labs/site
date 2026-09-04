// IMPORTS ---------------------------------------------------------------------

import filepath
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import simplifile
import site/document.{type Document}
import site/page
import site/route

// MAIN ------------------------------------------------------------------------

pub fn main() -> Nil {
  let documents = collect_content()
  let routes =
    documents
    |> dict.keys
    |> list.filter_map(route.from_path)

  let assert Ok(assets) = simplifile.get_files("assets")
  let assert Ok(_) = simplifile.delete_all(["dist"])
  let assert Ok(_) = simplifile.create_directory_all("dist")

  list.each([route.Index, ..routes], build_route(_, documents))
  list.each(assets, copy_asset)

  io.println("Built site in dist/")
}

fn build_route(
  route: route.Route,
  documents: Dict(String, Document),
) -> Result(Nil, simplifile.FileError) {
  let meta = route.to_meta(route, documents)
  let content = route.to_content(route, documents)
  let html = page.to_html(meta, [], content)
  let path = filepath.join("dist", route.to_filename(route))

  let assert Ok(_) =
    simplifile.create_directory_all(filepath.directory_name(path))
  let assert Ok(_) = simplifile.write(path, html)
}

fn copy_asset(asset: String) -> Result(Nil, simplifile.FileError) {
  let assert "assets/" <> name = asset
  let path = filepath.join("dist", name)

  let assert Ok(_) =
    simplifile.create_directory_all(filepath.directory_name(path))
  let assert Ok(_) = simplifile.copy_file(asset, path)
}

// UTILS -----------------------------------------------------------------------

pub fn collect_content() -> Dict(String, Document) {
  let assert Ok(files) = simplifile.get_files("content")
  use content, path <- list.fold(files, dict.new())
  let assert Ok(document) = simplifile.read(path) |> result.map(document.parse)
  let assert "content/" <> name = filepath.strip_extension(path)

  dict.insert(content, name, document)
}
