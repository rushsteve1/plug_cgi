defmodule Plug.CGI do
  @moduledoc """
  Primary public module for `plug_cgi`.
  See [`run/1`](https://hexdocs.pm/plug_cgi/Plug.CGI.html#run/2)
  below for the main entrypoint of `plug_cgi`.

  This module can also be used in a supervisor since it provides a `child_spec/1`
  ```
  children = [
    {Plug.CGI, splug: MyPlug, options: [log_device: :stdio]}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
  ```
  """

  def child_spec(args) do
    %{
      id: Plug.CGI,
      start: {Plug.CGI, :start_link, [args]}
    }
  end

  def start_link(args) do
    plug = Keyword.get(args, :plug, Plug.Debugger)
    args = Keyword.delete(args, :plug)

    run(plug, args)
  end

  @doc """
  The entrypoint of `Plug.CGI`, called to start the Plug chain starting with `plug`.

  The `log_device` option sets the default device for
  [`Logger.Backends.Console`](https://hexdocs.pm/logger/Logger.Backends.Console.html),
  defaults to `:standard_error`.
  The `output_device` option sets the default output for the CGI response,
  defaults to `:stdio`.

  The `opts` argument is also passed along to
  [`Plug.init/1`](https://hexdocs.pm/plug/Plug.html#c:init/1) for the given `plug`
  and `call_opts` option will be passed into
  [`Plug.call/2`](https://hexdocs.pm/plug/Plug.html#c:call/2) for the given `plug`.

  ## Example
  ```
  defmodule MyPlug do
    import Plug.Conn

    def init(options), do: options

    def call(conn, _opts) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello world")
    end
  end

  Plug.CGI.run MyPlug
  ```
  """
  @spec run(atom(), Keyword.t()) :: Plug.Conn.t()
  def run(plug, opts \\ []) when is_atom(plug) do
    Application.ensure_started(Logger)
    log_device = Keyword.get(opts, :log_device, :standard_error)
    console = Application.fetch_env!(:logger, :console)
    Application.put_env(:logger, :console, Keyword.merge([device: log_device], console))

    conn =
      System.get_env()
      |> Plug.CGI.Conn.conn(opts)

    plug.init(opts)

    plug.call(conn, Keyword.get(opts, :call_opts))
  end
end
