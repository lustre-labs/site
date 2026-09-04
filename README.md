# lustre.build

A number of scripts are provided in `dev/` that can be run to work on the site or
prepare it for production:

- `gleam run -m site/serve` to start the development server. This watches for
  changes to assets, djot content, and Gleam source code and performs hot
  replacement on pages that are open.

- `gleam run -m site/build` to statically build the site's HTML pages. Not yet
  implemented.
