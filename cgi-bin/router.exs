#!/usr/bin/env elixir
#
# An extremely simple example of a Plug

Mix.install([
  {:plug_cgi, path: "."}
])

# Adapted from the Plug README
defmodule RouterPlug do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end

Plug.CGI.run RouterPlug
