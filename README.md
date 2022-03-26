# Plug_CGI

A Plug adapter for the Common Gateway Interface,
allowing you to use all your favorite middleware and tools with the simplicity
of CGI web servers.

See the [Plug documentation](https://hexdocs.pm/plug/) for more information.

- https://datatracker.ietf.org/doc/html/rfc3875
- https://en.wikipedia.org/wiki/Common_Gateway_Interface

## Example

There are more examples in the [`cgi-bin` folder](./cgi-bin).

```elixir
#!/usr/bin/env elixir

# Install plug_cgi as a dependency
Mix.install([
  :plug_cgi
])

# Define your plug
# You can use middleware, routing, or anything else
defmodule MyPlug do
  import Plug.Conn

  def init(options) do
    # initialize options
    options
  end

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello world")
  end
end

# Run your plug with plug_cgi
Plug.CGI.run MyPlug
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `plug_cgi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_cgi, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/plug_cgi>.
