defmodule PlugCGITest do
  use ExUnit.Case
  doctest Plug.CGI

  # Example CGI request adapted from Wikipedia
  @req_body "field1=value1&field2=value2"
  @req_body_length @req_body |> byte_size() |> Integer.to_string()
  @env %{
    "GATEWAY_INTERFACE" => "CGI/1.1",
    "CONTENT_TYPE" => "application/x-www-form-urlencoded",
    "CONTENT_LENGTH" => @req_body_length,
    "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "HTTP_ACCEPT_CHARSET" => "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "HTTP_ACCEPT_ENCODING" => "gzip, deflate, br",
    "HTTP_ACCEPT_LANGUAGE" => "en-us,en;q=0.5",
    "HTTP_CONNECTION" => "keep-alive",
    "HTTP_HOST" => "example.com",
    "HTTP_COOKIE" => "name=value; name2=value2; name3=value3",
    "HTTP_USER_AGENT" =>
      "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:67.0) Gecko/20100101 Firefox/67.0",
    "PATH" => "/home/SYSTEM/bin:/bin:/cygdrive/c/progra~2/php:/cygdrive/c/windows/system32:...",
    "PATH_INFO" => "/foo/bar",
    "QUERY_STRING" => "var1=value1&var2=with%20percent%20encoding",
    "REMOTE_ADDR" => "127.0.0.1",
    "REMOTE_PORT" => "63555",
    "REQUEST_METHOD" => "POST",
    "REQUEST_URI" => "/cgi-bin/printenv.pl/foo/bar?var1=value1&var2=with%20percent%20encoding",
    "SCRIPT_NAME" => "/cgi-bin/printenv.pl",
    "SERVER_ADDR" => "127.0.0.1",
    "SERVER_ADMIN" => "(server admin's email address)",
    "SERVER_NAME" => "127.0.0.1",
    "SERVER_PORT" => "80",
    "SERVER_PROTOCOL" => "HTTP/1.1"
  }

  setup do
    {:ok, pid} = StringIO.open("")
    conn = Plug.CGI.Conn.conn(@env, test_body: @req_body, output_device: pid)

    [conn: conn, output_device: pid]
  end

  test "creates conn ", state do
    assert %Plug.Conn{} = state.conn
  end

  test "conn has host", state do
    assert "127.0.0.1" == state.conn.host
  end

  test "conn has method", state do
    assert "POST" == state.conn.method
  end

  test "conn has path info", state do
    assert ["foo", "bar"] == state.conn.path_info
  end

  test "conn has script name", state do
    assert ["cgi-bin", "printenv.pl"] == state.conn.script_name
  end

  test "conn has request path", state do
    assert "/foo/bar" == state.conn.request_path
  end

  test "conn has port", state do
    assert 80 == state.conn.port
  end

  test "conn has remote IP", state do
    assert {127, 0, 0, 1} == state.conn.remote_ip
  end

  test "conn has any request headers", state do
    assert is_list(state.conn.req_headers)
  end

  test "conn has scheme", state do
    assert :http == state.conn.scheme
  end

  test "conn has query string", state do
    assert "var1=value1&var2=with%20percent%20encoding" == state.conn.query_string
  end

  test "can fetch query params", state do
    assert %{"var1" => "value1", "var2" => "with percent encoding"} ==
             state.conn
             |> Plug.Conn.fetch_query_params()
             |> Map.get(:query_params)
  end

  test "conn has proper headers", state do
    headers =
      [
        {"content-length", @req_body_length},
        {"content-type", "application/x-www-form-urlencoded"},
        {"accept-charset", "ISO-8859-1,utf-8;q=0.7,*;q=0.7"},
        {"accept-encoding", "gzip, deflate, br"},
        {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
        {"user-agent",
         "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:67.0) Gecko/20100101 Firefox/67.0"},
        {"connection", "keep-alive"},
        {"accept-language", "en-us,en;q=0.5"},
        {"cookie", "name=value; name2=value2; name3=value3"},
        {"host", "example.com"}
      ]
      |> Enum.sort()

    assert headers == state.conn.req_headers
  end

  test "can fetch cookies", state do
    assert %{"name" => "value", "name2" => "value2", "name3" => "value3"} ==
             state.conn |> Plug.Conn.fetch_cookies() |> Map.get(:req_cookies)
  end

  test "can read request body", state do
    assert {:ok, @req_body, %Plug.Conn{}} = state.conn |> Plug.Conn.read_body()
  end

  test "can respond with a body", state do
    body = "Hello world"

    state.conn
    |> Plug.Conn.send_resp(200, body)

    assert StringIO.flush(state.output_device) =~ body
  end

  test "can respond with a file", state do
    # Arbitrary short file
    path = ".tool-versions"

    state.conn
    |> Plug.Conn.send_file(200, path)

    assert StringIO.flush(state.output_device) =~ File.read!(path)
  end

  test "can respond with an added header", state do
    header = "hello"
    val = "world"
    body = "Hello world"

    state.conn
    |> Plug.Conn.put_resp_header(header, val)
    |> Plug.Conn.send_resp(200, body)

    resp = StringIO.flush(state.output_device)

    assert resp =~ body and resp =~ header and resp =~ val
  end

  test "can send chunked response", state do
    conn =
      state.conn
      |> Plug.Conn.send_chunked(200)

    assert StringIO.flush(state.output_device) =~ @env["SERVER_PROTOCOL"]

    part1 = "hello there"

    {:ok, conn} =
      conn
      |> Plug.Conn.chunk(part1)

    assert StringIO.flush(state.output_device) =~ part1

    part2 = "general kenobi"

    {:ok, _} =
      conn
      |> Plug.Conn.chunk(part2)

    assert StringIO.flush(state.output_device) =~ part2
  end
end
