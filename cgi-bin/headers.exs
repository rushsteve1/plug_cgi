#!/usr/bin/env elixir
#
# A plug that prints all request headers

Mix.install([
  {:plug_cgi, path: "."}
])

defmodule HeadersPlug do
  import Plug.Conn

  @template """
  <ul>
  <%= for {k, v} <- headers do %>
    <li><strong><%= k %></strong>: <%= v %></li>
  <% end %>
  </ul>
  """

  def init(options) do
    # initialize options
    options
  end

  def call(conn, _opts) do
    body = EEx.eval_string(@template, headers: conn.req_headers)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, body)
  end
end

Plug.CGI.run(HeadersPlug)
