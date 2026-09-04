// IMPORTS ---------------------------------------------------------------------

import booklet.{type Booklet}
import child_process
import child_process/stdio
import ewe
import filepath
import gleam/bool
import gleam/bytes_tree
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Name}
import gleam/http/request.{type Request, Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/static_supervisor
import gleam/otp/supervision.{type ChildSpecification}
import gleam/result
import group_registry.{type GroupRegistry}
import lustre/element
import lustre/element/html
import marceau
import polly.{type Watcher}
import simplifile
import site/build
import site/document.{type Document}
import site/page
import site/route.{type Route}

// MAIN ------------------------------------------------------------------------

pub fn main() -> Nil {
  let registry = process.new_name("registry")
  let content = booklet.new(build.collect_content())

  let assert Ok(_) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(create_registry(registry))
    |> static_supervisor.add(watch_assets(registry))
    |> static_supervisor.add(watch_content(registry, content))
    |> static_supervisor.add(watch_source(registry))
    |> static_supervisor.add(serve_site(registry, content))
    |> static_supervisor.start

  process.sleep_forever()
}

// PUBSUB ----------------------------------------------------------------------

fn create_registry(
  registry: Name(group_registry.Message(a)),
) -> ChildSpecification(GroupRegistry(a)) {
  group_registry.supervised(registry)
}

// FILE WATCHERS ---------------------------------------------------------------

fn watch_assets(
  registry: Name(group_registry.Message(String)),
) -> ChildSpecification(Watcher) {
  polly.new()
  |> polly.interval(100)
  |> polly.add_dir("assets")
  |> polly.add_callback(fn(event) {
    let assert "assets" <> path = event.path
    let registry = group_registry.get_registry(registry)
    let subscribers = group_registry.members(registry, "assets")
    use subscriber <- list.each(subscribers)

    process.send(subscriber, path)
  })
  |> polly.supervised
}

fn watch_content(
  registry: Name(group_registry.Message(String)),
  content: Booklet(Dict(String, Document)),
) -> ChildSpecification(Watcher) {
  polly.new()
  |> polly.interval(100)
  |> polly.add_dir("content")
  |> polly.add_callback(fn(event) {
    let assert "content/" <> path = filepath.strip_extension(event.path)

    booklet.update(content, case simplifile.read(event.path) {
      Ok(source) -> dict.insert(_, path, document.parse(source))
      Error(_) -> dict.delete(_, path)
    })

    let registry = group_registry.get_registry(registry)
    let subscribers = group_registry.members(registry, "content")
    use subscriber <- list.each(subscribers)

    process.send(subscriber, path)
  })
  |> polly.supervised
}

fn watch_source(
  registry: Name(group_registry.Message(String)),
) -> ChildSpecification(Watcher) {
  polly.new()
  |> polly.interval(100)
  |> polly.add_dir("src")
  |> polly.add_callback(fn(_) {
    let result =
      child_process.from_name("gleam")
      |> child_process.arg("build")
      |> child_process.run(mode: stdio.capture(True))

    case result {
      Error(error) ->
        io.println_error(child_process.describe_start_error(error))
      Ok(child_process.Output(status_code: 0, ..)) -> {
        case reload_modified_modules() {
          Error(error) -> io.println_error(error)
          Ok(Nil) -> {
            let registry = group_registry.get_registry(registry)
            let subscribers = group_registry.members(registry, "source")
            use subscriber <- list.each(subscribers)

            process.send(subscriber, "")
          }
        }
      }
      Ok(child_process.Output(output:, ..)) -> io.println_error(output)
    }
  })
  |> polly.supervised
}

@external(erlang, "serve_ffi", "reload_modified_modules")
fn reload_modified_modules() -> Result(Nil, String)

// WEB SERVER ------------------------------------------------------------------

fn serve_site(
  registry: Name(group_registry.Message(String)),
  content: Booklet(Dict(String, Document)),
) -> ChildSpecification(static_supervisor.Supervisor) {
  let listener = process.new_name("listener")
  let pool = process.new_name("connection-pool")

  ewe.new(listener, pool, fn(request: Request(_)) -> Response(_) {
    use <- serve_assets(request)
    use <- serve_pages(request, content)
    use <- serve_sse(request, registry, content)

    response.set_body(
      response.new(404),
      ewe.Bytes(bytes_tree.from_string("not found")),
    )
  })
  |> ewe.listening(1234)
  |> ewe.supervised
}

fn serve_assets(request: Request(_), next: fn() -> Response(_)) -> Response(_) {
  let path = filepath.join("assets", request.path)

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

fn serve_pages(
  request: Request(_),
  content: Booklet(Dict(String, Document)),
  next: fn() -> Response(_),
) -> Response(_) {
  let request = Request(..request, path: filepath.strip_extension(request.path))

  case route.from_path(request.path) {
    Ok(route) -> {
      let meta = route.to_meta(route, booklet.get(content))
      let content = route.to_content(route, booklet.get(content))
      let head = [
        html.script([], {
          "
            const page = window.location.pathname;
            const eventSource = new EventSource(`/.dev/sse?path=${page}`);

            eventSource.onmessage = event => {
              console.log('Received unknown event:', event);
            }

            eventSource.addEventListener('asset-change', (event) => {
              console.log('Asset changed:', event.data);
              const path = event.data;
              const timestamp = Date.now();

              document.querySelectorAll('[href]').forEach((el) => {
                const url = new URL(el.href, location.href);
                if (url.pathname === path) {
                  url.searchParams.set('t', timestamp);
                  el.href = url.toString();
                }
              });

              document.querySelectorAll('[src]').forEach((el) => {
                const url = new URL(el.src, location.href);
                if (url.pathname === path) {
                  url.searchParams.set('t', timestamp);
                  el.src = url.toString();
                }
              });

              document.querySelectorAll('link[rel=\"stylesheet\"]').forEach((el) => {
                try {
                  for (const rule of el.sheet?.cssRules ?? []) {
                    if (rule instanceof CSSImportRule) {
                      const importUrl = new URL(rule.href, location.href);

                      if (importUrl.pathname === path) {
                        const url = new URL(el.href, location.href);
                        url.searchParams.set('t', timestamp);
                        el.href = url.toString();

                        break;
                      }
                    }
                  }
                } catch (_) {}
              });
            });

            eventSource.addEventListener('content-change', (event) => {
              console.log('Content changed:', event.data);
              document.body.innerHTML = event.data;
            })
          "
        }),
      ]

      let html = page.to_html(meta, head, content)
      let body = ewe.Bytes(bytes_tree.from_string(html))

      response.new(200)
      |> response.set_body(body)
      |> response.set_header("content-type", "text/html; charset=utf-8")
    }

    Error(_) -> next()
  }
}

// HOT ASSET REPLACEMENT -------------------------------------------------------

fn serve_sse(
  request: Request(_),
  registry: Name(group_registry.Message(String)),
  content: Booklet(Dict(String, Document)),
  next: fn() -> Response(_),
) -> Response(_) {
  use <- bool.lazy_guard(request.path != "/.dev/sse", next)

  let route =
    request.get_query(request)
    |> result.try(list.key_find(_, "path"))
    |> result.try(route.from_path)

  use _, selector <- ewe.sse(
    response.new(200),
    handler: fn(connection, _, message) {
      case message {
        Some(event) ->
          case ewe.send_event(connection, event) {
            Ok(_) -> ewe.continue(Nil)
            Error(_) -> ewe.stop()
          }

        None -> ewe.continue(Nil)
      }
    },
    on_close: fn(_, _) { Nil },
  )

  let self = process.self()
  let registry = group_registry.get_registry(registry)

  let selector =
    selector
    |> process.merge_selector(on_asset_change(registry, self))
    |> process.merge_selector(on_content_change(registry, self, content, route))
    |> process.merge_selector(on_source_change(registry, self, content, route))

  #(Nil, selector)
}

fn on_asset_change(
  registry: GroupRegistry(String),
  self: process.Pid,
) -> process.Selector(Option(ewe.SseEvent)) {
  let subject = group_registry.join(registry, "assets", self)
  use path <- process.select_map(process.new_selector(), subject)

  ewe.event(path)
  |> ewe.event_name("asset-change")
  |> Some
}

fn on_source_change(
  registry: GroupRegistry(String),
  self: process.Pid,
  content: Booklet(Dict(String, Document)),
  route: Result(Route, Nil),
) -> process.Selector(Option(ewe.SseEvent)) {
  case route {
    Error(_) -> process.new_selector()
    Ok(route) -> {
      let subject = group_registry.join(registry, "source", self)
      use _ <- process.select_map(process.new_selector(), subject)

      content_changed(route, booklet.get(content))
    }
  }
}

fn on_content_change(
  registry: GroupRegistry(String),
  self: process.Pid,
  content: Booklet(Dict(String, Document)),
  route: Result(Route, Nil),
) -> process.Selector(Option(ewe.SseEvent)) {
  case route {
    Error(_) -> process.new_selector()
    Ok(route) -> {
      let subject = group_registry.join(registry, "content", self)
      use path <- process.select_map(process.new_selector(), subject)
      let documents = booklet.get(content)
      let meta = route.to_meta(route, documents)
      use <- bool.guard(!list.contains(meta.content, path), None)

      content_changed(route, documents)
    }
  }
}

fn content_changed(
  route: Route,
  documents: Dict(String, Document),
) -> Option(ewe.SseEvent) {
  route
  |> route.to_content(documents)
  |> element.to_string
  |> ewe.event
  |> ewe.event_name("content-change")
  |> Some
}
