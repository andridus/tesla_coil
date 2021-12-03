route_macros =
  [:get, :post, :put, :patch, :delete, :options, :connect, :trace, :head]
  |> Enum.map(&{&1, 3})

# using a second variable even if the value is the same for now, for the sake of maintainability
# its a little better to understand when reading and add new values to the list in future

locals_without_parens = route_macros

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: locals_without_parens
  ],
  locals_without_parens: locals_without_parens
]
