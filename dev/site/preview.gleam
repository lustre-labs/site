import ewe
import filepath
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{None}
import gleam/otp/static_supervisor
import gleam/otp/supervision
import marceau
import simplifile
import site/build

/// Preview first builds the final page, then serves it from `dist/` using a
/// local file server.
///
/// This can be used to test the built artefacts before deployment.
pub fn main() {
  build.main()

  let assert Ok(_) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(serve_site())
    |> static_supervisor.start

  process.sleep_forever()
}

fn serve_site() -> supervision.ChildSpecification(static_supervisor.Supervisor) {
  let listener = process.new_name("listener")
  let pool = process.new_name("connection-pool")

  ewe.new(listener, pool, fn(request: Request(_)) -> Response(_) {
    use <- serve_dist(request)

    response.set_body(
      response.new(404),
      ewe.Bytes(bytes_tree.from_string("not found")),
    )
  })
  |> ewe.listening(1235)
  |> ewe.supervised
}

fn serve_dist(
  request: Request(ewe.Connection),
  next: fn() -> Response(ewe.Body),
) -> Response(ewe.Body) {
  let path = filepath.join("dist", request.path)

  use <- serve_file(request, path)
  use <- serve_file(request, filepath.join(path, "index.html"))

  next()
}

fn serve_file(
  request: Request(ewe.Connection),
  path: String,
  next: fn() -> Response(ewe.Body),
) -> Response(ewe.Body) {
  case simplifile.is_file(path) {
    Ok(False) | Error(_) -> next()
    Ok(True) -> {
      let assert Ok(ext) = filepath.extension(path)
      let assert Ok(file) =
        ewe.file(request.body, path, offset: None, limit: None)

      let mime = marceau.extension_to_mime_type(ext)

      response.new(200)
      |> response.set_body(file)
      |> response.set_header("content-type", mime)
    }
  }
}
