defmodule Plug.CGI.Conn do
  @behaviour Plug.Conn.Adapter
  @moduledoc false
  @known_headers ["CONTENT_LENGTH", "CONTENT_TYPE"]

  # Based on the example and Cowboy implementations
  # https://github.com/elixir-plug/plug/blob/master/lib/plug/adapters/test/conn.ex
  # https://github.com/elixir-plug/plug_cowboy/blob/master/lib/plug/cowboy/conn.ex

  def conn(env, opts \\ []) when is_map(env) do
    scheme = if Map.get(env, "HTTPS"), do: :https, else: :http

    {:ok, remote_ip} =
      Map.get(env, "REMOTE_ADDR", "0.0.0.0") |> to_charlist() |> :inet.parse_address()

    adapter =
      {__MODULE__,
       %{
         raw_protcol: Map.get(env, "SERVER_PROTOCOL", "HTTP/1.0"),
         test_body: Keyword.get(opts, :test_body),
         output_device: Keyword.get(opts, :output_device, :stdio)
       }}

    path = Map.get(env, "PATH_INFO", "/")

    %Plug.Conn{
      adapter: adapter,
      scheme: scheme,
      host: Map.get(env, "SERVER_NAME", ""),
      method: Map.get(env, "REQUEST_METHOD", "") |> String.upcase(),
      owner: self(),
      remote_ip: remote_ip,
      request_path: path,
      path_info: path |> split_path(),
      script_name: Map.get(env, "SCRIPT_NAME", "") |> split_path(),
      query_string: Map.get(env, "QUERY_STRING", ""),
      port: Map.get(env, "SERVER_PORT", "-1") |> String.to_integer(),
      req_headers: request_headers(env)
    }
  end

  @impl true
  def upgrade(_payload, _protocol, _opts) do
    # CGI only supports HTTP/1.1 so upgrading is not supported
    {:error, :not_supported}
  end

  @impl true
  def chunk(%Plug.Conn{method: "HEAD"} = _payload, _body), do: :ok

  @impl true
  def chunk(payload, body) do
    if body, do: IO.write(payload.output_device, body)

    :ok
  end

  @impl true
  def get_http_protocol(payload), do: payload.raw_protcol

  @impl true
  def get_peer_data(payload) do
    %{
      address: payload.remote_ip,
      port: payload.port,
      ssl_cert: nil
    }
  end

  @impl true
  def inform(_payload, _status, _headers), do: {:error, :not_supported}

  @impl true
  def push(_payload, _path, _headers), do: {:error, :not_supported}

  @impl true
  def read_req_body(%{test_body: body} = payload, _options),
    do: {:ok, body, payload}

  @impl true
  def read_req_body(payload, options) do
    size = Keyword.get(options, :length, :eof)
    body = IO.read(:stdio, size)

    if size != :eof and String.length(body) <= size do
      {:more, body, payload}
    else
      {:ok, body, payload}
    end
  end

  @impl true
  def send_chunked(%{method: "HEAD"} = payload, status, headers) do
    send_headers(payload, status, headers)

    {:ok, nil, payload}
  end

  @impl true
  def send_chunked(payload, status, headers) do
    send_headers(payload, status, headers)

    {:ok, nil, payload}
  end

  @impl true
  def send_file(%Plug.Conn{method: "HEAD"} = payload, status, headers, _path, _offset, _length) do
    send_headers(payload, status, headers)

    {:ok, nil, payload}
  end

  @impl true
  def send_file(payload, status, headers, path, offset, length) do
    %File.Stat{type: :regular, size: size} = File.stat!(path)

    length =
      cond do
        length == :all -> size
        is_integer(length) -> length
      end

    send_headers(payload, status, [{"content-length", length |> Integer.to_string()} | headers])

    body =
      File.stream!(path, [], 1)
      |> Stream.drop(offset)
      |> Enum.take(length)
      |> to_string()

    IO.write(payload.output_device, body)

    {:ok, nil, payload}
  end

  @impl true
  def send_resp(%Plug.Conn{method: "HEAD"} = payload, status, headers, _body) do
    send_headers(payload, status, headers)

    {:ok, nil, payload}
  end

  @impl true
  def send_resp(payload, status, headers, body) do
    send_headers(payload, status, [
      {"content-length", body |> byte_size() |> Integer.to_string()} | headers
    ])

    # Blank line between header and body
    IO.write(payload.output_device, body)

    {:ok, nil, payload}
  end

  # === Private Helpers ===

  defp split_path(nil), do: []

  defp split_path(path) do
    :binary.split(path, "/", [:global])
    |> Enum.filter(&(&1 != ""))
  end

  defp http_header(payload, status) do
    get_http_protocol(payload) <>
      " " <> Integer.to_string(status) <> " " <> Plug.Conn.Status.reason_phrase(status)
  end

  defp send_headers(payload, status, headers) do
    IO.puts(payload.output_device, http_header(payload, status))

    for header <- headers do
      IO.puts(payload.output_device, elem(header, 0) <> ": " <> elem(header, 1))
    end

    # Blank line between header and body
    IO.puts("")
  end

  defp slugify(str) do
    str
    |> String.replace_prefix("HTTP_", "")
    |> String.downcase()
    |> String.replace("_", "-")
  end

  defp try_header(_env, {envvar, val}) do
    {slugify(envvar), val}
  end

  defp try_header(env, var) do
    case Map.get(env, var) do
      nil -> nil
      val -> {slugify(var), val}
    end
  end

  defp get_dyn_headers(env) do
    env
    |> Enum.filter(fn {k, _} -> String.starts_with?(k, "HTTP_") end)
  end

  defp request_headers(env) do
    env
    |> get_dyn_headers()
    |> Stream.concat(@known_headers)
    |> Stream.map(&try_header(env, &1))
    |> Stream.filter(fn
      nil -> false
      {_, v} -> v && v != ""
    end)
    |> Enum.sort()
  end
end
