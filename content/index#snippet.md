## You already know it

Lustre code is just Gleam code: there's no new syntax to learn or a templating
language with just a subset of features. That means writing view functions with
a best-in-class language server, full type checking, and access to all of Gleam's
features like pattern matching and use expressions.

```gleam
fn view_task_list(
  tasks: RemoteData(List(Task)),
  selected: Option(Id),
) -> Element(Message) {
  case tasks {
    NotFetched | Loading ->
      html.span([attribute.class("text-muted animate-pulse")], [
        html.text("Loading tasks..."),
      ])

    Failed(message) ->
      html.span([attribute.class("text-red-500")], [
        html.text(string.concat(["Failed to load tasks: ", message])),
      ])

    Ready([]) -> 
      html.span([attribute.class("text-muted")], [
        html.text("All done!"),
      ])

    Ready(tasks) ->
      keyed.ul([attribute.class("space-y-2")], {
        use task <- list.map(tasks)
        let key = id.to_string(task.id)
        let html = view_task(task:, selected:, on_click: UserToggledTask(task.id))

        #(key, html)
      })
  }
}
```