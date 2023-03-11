defmodule PlugCgi.MixProject do
  use Mix.Project

  @version "0.1.4"
  @repo_url "https://github.com/rushsteve1/plug_cgi"

  def project do
    [
      app: :plug_cgi,
      version: @version,
      elixir: "~> 1.7",
      source_url: @repo_url,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      description: "Plug adapter for the Common Gateway Interface",
      aliases: ["cgi.serve": ["cmd python3 -m http.server --cgi"]]
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
      {:plug, "~> 1.14"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  def docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @repo_url
    ]
  end
end
