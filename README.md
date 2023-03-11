# Plug_CGI

[Hex Package](https://hex.pm/packages/plug_cgi)
[Hex Docs](https://hexdocs.pm/plug_cgi)

A Plug adapter for the Common Gateway Interface,
allowing you to use all your favorite middleware and tools with the simplicity
of CGI web servers.

See the [Plug documentation](https://hexdocs.pm/plug/) for more information.

- https://datatracker.ietf.org/doc/html/rfc3875
- https://en.wikipedia.org/wiki/Common_Gateway_Interface

## Example

There are more examples in the
[`cgi-bin` folder](https://github.com/rushsteve1/plug_cgi/tree/main/cgi-bin).

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

The package can be installed by adding `plug_cgi` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:plug_cgi, "~> 0.1.0"}
  ]
end
```

## Single-File Elixir Scripts

You can use `plug_cgi` in
[single-file Elixir scripts](https://fly.io/phoenix-files/single-file-elixir-scripts/)
by adding it to your `Mix.install/2` call:

```elixir
Mix.install([ 
  :plug_cgi, 
])
```

When using single-file scripts with CGI you may need to set your `HOME`
environment variable. This can be done by editing the shebang line to:

```sh
#!/usr/bin/env HOME=/home/user elixir
```
