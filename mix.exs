defmodule PlugCgi.MixProject do
  use Mix.Project

  def project do
    [
      app: :plug_cgi,
      version: "0.1.0",
      elixir: "~> 1.13",
      source_url: "https://github.com/rushsteve1/plug_cgi",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.13"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rushsteve1/plug_cgi"}
    ]
  end

  defp description do
    "Plug adapter for the Common Gateway Interface"
  end

  defp aliases do
    [
      "cgi.serve": ["cmd python3 -m http.server --cgi"]
    ]
  end
end
