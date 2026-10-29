import argv
import gleam/io
import site/build
import site/preview
import site/serve

pub fn main() {
  case argv.load().arguments {
    ["build"] -> build.main()
    ["preview"] -> preview.main()
    ["serve"] -> serve.main()

    _ -> io.println("Expected usage `gleam dev (build | preview | serve)`")
  }
}
