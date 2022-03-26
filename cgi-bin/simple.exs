#!/usr/bin/env elixir
#
# An extremely simple example of a Plug

Mix.install([
  {:plug_cgi, path: "."}
])

# Taken from the Plug README
defmodule SimplePlug do
  import Plug.Conn

  def init(options) do
    # initialize options
    options
  end

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("test", "hello there!")
    |> send_resp(200, "Hello world")
  end
end

Plug.CGI.run SimplePlug
