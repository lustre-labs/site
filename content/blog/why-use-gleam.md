---
title = "Why use Gleam?"
description = "A look at what makes Gleam such a joyful language for building modern Web applications."
author = ["hayleigh"]
---

For many folks, Lustre will be their first introduction to [Gleam](https://gleam.run).
Adopting a new language to try out a new framework is quite a tall order, so let's
take a look at what Gleam gives us and what makes it a great choice for building
modern Web applications.

We think it comes down to three things:

1. The language is small and easy to pick up. [#](#It's-easy-to-pick-up)

2. The tooling and developer experience is really quite good. [#](#Access-to-best-in-class-tooling)

3. The community is very friendly and willing to help. [#](#A-small-but-passionate-community)

If that's already enough to convince you, you can jump right into Lustre's
[quickstart guide](#) and get a feel for Gleam by building something. Otherwise,
read on!

## It's easy to pick up

Gleam is a _statically typed functional programming language_. That might conjure
up images of an overly academic language with funky syntax and an odd obsession
with [burritos](https://blog.plover.com/prog/burritos.html), but Gleam is designed
to be familiar and quick to learn.

Most folks should find Gleam's C-style syntax easy to pick up, and the language
shares a similar design philosophy to languages like Elm and Go with an empahsis
on a small core language and a strong preference of "one way to do things."

::: figure
```gleam
// Imports
import lustre/element.{type Element}

// Function definitions...
fn button(on_click handle_click: message, label text: String) -> Element(message) { 
  todo as "... and placeholders"
}

// Custom types
type User {
  LoggedIn(name: String, email: String)
  Anonymous
}

// Pattern matching
case list_of_ints {
  [first, ..rest] -> first
  [] -> 0
}

// Callback syntax sugar
use data <- result.try(load_user())

// Data pipelines...
[1, 2, 3]
|> list.map(fn(n) { n * 2 })
|> echo as "... and debug printing"
```

We've shown off almost all of Gleam's syntax in this little snippet, but we've
missed out a few interesting things like [function captures](https://tour.gleam.run/functions/function-captures/)
or [bit array literals](https://tour.gleam.run/data-types/bit-arrays/).
:::

Gleam has a great [interactive tour](https://tour.gleam.run/table-of-contents/)
that can help folks get up to speed quickly, and there's also a large 
[Exercism track](https://exercism.org/tracks/gleam) which is particularly good for
folks not used to functional programming.

Being a small language has some real benefits when it comes to revisiting old code
or onboarding new team members! When you can hold more of the language in your head,
you can spend more time focusing on what your code does or the problem you're trying
to solve.

## Access to best-in-class tooling

Gleam's language server has been in steady development for over four years now and
it punches well above its weight. The language server comes with over 30 code
actions, including things like: "Generate function", "Add missing patterns", and
"Interpolate string." Because Lustre doesn't require a separate templating language,
you have access to all these actions when writing your Lustre apps.

To get an idea for what that experience is like, take a look at this quick demo
[@giacomocavalieri](https://giacomocavalieri.me/) put together for us:


::: figure
```=html
<video src="/video/lsp-demo.mp4" autoplay loop muted ></video>
```

Writing Gleam is a breeze when the language server can generate half the code for
you.
:::

The language server is built right into the compiler, so if your editor supports
the Language Server Protocol all you to do is point it at the Gleam binary and
you're good to go! Most modern text editors support language servers with
little-to-no config but if you're unsure, Gleam has some [setup docs](https://gleam.run/language-server/#Installation)
for common editors.

On top of that the compiler also includes other bits of important tooling like
the formatter and the package manager, meaning a single binary is all you need to
get going.

This sounds like a small thing, but tooling and config fatigue are big problems
with modern Web development. While there are many great projects trying to solve
this for JavaScript, having a single _official_ binary that covers all the things
you need out of the box can make it easier to try out Gleam than even other
JavaScript frameworks. 

Beyond editor tooling, Gleam takes a page out of Rust's book and has clear, helpful
error and warning messages. 

::: figure
``` terminal
error: Unknown record field

  ┌─ ./src/app.gleam:8:16
  │
8 │ user.alias
  │     ^^^^^^ Did you mean `name`?

The value being accessed has this type:
    User

It has these fields:
    .email
    .name
    
--------------------------------------------------------------------------------
    
error: Inexhaustive patterns
    ┌─ ./src/app/post.gleam:55:3
    │
 55 │ ╭   case block {
 56 │ │     jot.Paragraph(attributes:, content:) ->
    · │
190 │ │   }
    │ ╰───^

This case expression does not have a pattern for all possible values. If it
is run on one of the values without a pattern then it will crash.

The missing patterns are:

    jot.Codeblock(attributes:, language:, content:)
```

Gleam's error messages always try to provide additional context and suggestions
on how to resolve the error.
:::

This focus on developer experience helps explain why Gleam was the second-most
admired language in the [2025 Stack Overflow survey](https://survey.stackoverflow.co/2025/technology#2-programming-scripting-and-markup-languages)!


## A small but passionate community

Big languages have big communities and that often comes with access to a large
ecosystem of packages, blog posts, and learning resources. Coming to a smaller
language can feel like giving up on a lot just to try something new, but something
often overlooked is the passion and friendliness of smaller communities.

Members of the Gleam core team and maintainers of popular packages (including us!)
are regularly online in the [Gleam Discord server](https://discord.gg/Fm8Pwmy)
answering questions and chatting about the language.

:::figure
``` discord
> nice-stranger : hiiiiiiiiiii, im transitioning from go to gleam
> lpil          : Sweet, I think they have a lot in common.
> nice-stranger : yes, i wanted to try out gleam as i heard its concurrency
                  handling is top notch
> nice-stranger : wait
> nice-stranger : excuse me, am i already speaking to the creator of gleam right
                  off the bat
> lpil          : Yeah I'm like really online.
```

Louis isn't even the most-online member of Gleam's core team!
:::


## The technical bits

You might have noticed that any mention of _language features_ has been absent
so far. These days it's easy to find a language with any combination of features
you might have in mind, so we've focused on some of the surrounding aspects that
make Gleam stand out. But if you're still not convinced or you like to know what
you're getting into, here's a super quick rundown of Gleam's more-interesting
features.

### Pattern matching in place of `if` and `switch` statements. 

Pattern matching is a powerful combination of JavaScript's `switch` statements
and destructuring assignments. It allows you to match on the shape of your data
and extract only the parts you care about.

::: figure
```gleam
fn view(model: Model) -> Element(Message) {
  case model.route, model.page, model.session {
    Home, HomeModel(page), _ -> 
      layout(model, home.view(page), HomeDispatchedMessage)

    Home, LoginModel(page), _ ->
      layout(model, login.view(page), LoginDispatchedMessage)

    Home, DashboardModel(page), Some(session) ->
      layout(model, dashboard.view(page, session), DashboardDispatchedMessage)

    _, _, _ ->
      layout(model, not_found.view(), NotFoundDispatchedMessage)
  }
}
```

Imagine trying to write this branching logic in TypeScript. 🤯
:::

### `use` notation to combat callback hell.

Do you remember back in the day when working with JavaScript meant nested callback
hell for things like async code or event handling? A lot of that pain was lifted
once `Promise` stepped onto the scene, but that still left out any other
callback-based APIs like result-based error handling.

Gleam has a nifty piece of syntax called [`use`](https://tour.gleam.run/advanced-features/use/)
that flattens out nested callbacks and makes code appear more linear. It's a bit
like `await` but works for any callback-based API.

::: figure
```gleam
fn on_global_mousemove(handler: fn(Int, Int) -> message) -> Effect(message) {
  use dispatch <- effect.from
  use event <- doccument.add_event_listener("mousemove")
  use #(x, y) <- result.try(decode.run(event, {
    use x <- decode.field("clientX", decode.int)
    use y <- decode.field("clientY", decode.int)

    decode.success(#(x, y))
  }))

  dispatch(handler(x, y))
}
```

Because the `use` expression isn't restricted to just one kind of callback, it's
possible to mix and match callbacks that do different things as long as the types
line up.
:::

These `use` expressions can often be a little intimidating to newcomers of the
language: it's probably Gleam's only "fancy" feature. Fortunately the language
server offers a code action to freely switch between `use` and callback style if
you're ever not sure what's going on.

### `BitArray` literal syntax and patterns.

This one is going to be niche but in the rare situations you need it, it can be
a lifesaver. Gleam (and other BEAM languages like Erlang and Elixir) can construct
and match on binary data using a literal syntax built into the language.

::: figure
```gleam
fn parse_dns_packet(data: BitArray) {
  //   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
  // ┌───────────────────────────────────────────────┐
  // │                      ID                       │
  // ├──┬───────────┬──┬──┬──┬──┬────────┬───────────┤
  // │QR│   OPCODE  │AA│TC│RD│RA│   Z    │   RCODE   │
  // ├──┴───────────┴──┴──┴──┴──┴────────┴───────────┤
  // │                    QDCOUNT                    │
  // ├───────────────────────────────────────────────┤
  // │                    ANCOUNT                    │
  // ├───────────────────────────────────────────────┤
  // │                    NSCOUNT                    │
  // ├───────────────────────────────────────────────┤
  // │                    ARCOUNT                    │
  // └───────────────────────────────────────────────┘
  case data {
    <<
      id:16,
      qr:1, opcode:4, aa:1, tc:1, rd:1, ra:1, z:3, rcode:4,
      qdcount:16,
      ancount:16,
      nscount:16,
      arcount:16,
    >> -> Ok(todo)
    _ -> Error("invalid dns packet")
  }
}
```

This nifty function, also provided by [@giacomocavalieri](https://bsky.app/profile/giacomocavalieri.me/post/3mjypzndksk2a),
shows how the memory layout of a DNS packet can be directly translated into a
bit array pattern match.
:::

Many Web apps will never need to make use of this feature, but if you're playing
around with more obscure Web APIs like the Web MIDI API or perhaps working with
binary WebSocket frames, Gleam's bit array syntax can make things feel remarkably
straight forward.

If you'd like to learn more about Bit Arrays, Gears has an
[excellent blog post](https://gearsco.de/blog/bit-array-syntax/) covering things
in detail.

## Ready to jump in?

If you made it this far, we hope that means you're at least a little bit curious
about Gleam and Lustre! If that's the case, here are some links to get you started:

{.wide}
::: actions
``` =toml
[[actions]]
title = "The Gleam language tour"
subtitle = "Learn more about Gleam's syntax and features."
link = "https://tour.gleam.run/table-of-contents/"

[[actions]]
title = "Lustre's quickstart guide"
subtitle = "Get a feel for all of Lustre's core features."
link = "https://hexdocs.pm/lustre/guide/01-quickstart.html"
```
:::
