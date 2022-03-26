#!/usr/bin/env elixir
#
# A plug that dumps all environment variables

Mix.install([
  {:plug_cgi, path: "."}
])

# Taken from the Plug README
defmodule VarsPlug do
  import Plug.Conn

  def init(options) do
    # initialize options
    options
  end

  def call(conn, _opts) do
    body = inspect(System.get_env(), pretty: true)
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, body)
  end
end

Plug.CGI.run VarsPlug
