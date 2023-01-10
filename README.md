# ExSecrets

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_secrets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_secrets, "~> 0.1.0"}
  ]
end
```

In a `dev` environment add the code below to your `config/dev.exs` file then point the path
to your **.env** file.

```elixir
  config :ex_secrets, :providers, %{
    dot_env: %{path: "/path/.env"}
  },
  default_provider: :dot_env
```
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_secrets>.

