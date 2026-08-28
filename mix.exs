defmodule ExSecrets.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_secrets,
      version: "0.4.0",
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExSecrets.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 0.4.3 or ~> 1.0"},
      # Dependecies.
      # Widened rather than moved: HTTPoison 3.0 is the first release to require
      # hackney 4.x, and hackney 1.x carries four open advisories (SSRF allowlist
      # bypass, CR/LF injection, a missing TLS handshake timeout). Pinning 1.8
      # held every consumer of this library on the vulnerable line.
      #
      # The range spans all three majors because the surface used here —
      # `HTTPoison.get/3`, `post/4`, and `%HTTPoison.Response{}` — is unchanged
      # across them, and callers already swap the client wholesale via
      # `config :ex_secrets, :http_adapter`.
      {:httpoison, "~> 1.8 or ~> 2.0 or ~> 3.0"},
      {:poison, "~> 3.1"},
      {:joken, "~> 2.6"},

      # Testing and Documentation
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14.0", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.11.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp description() do
    "Provider secrets to your app from .env, Azure KeyVault, Azure Managed Identity, Google Secret Manager."
  end

  defp package() do
    [
      name: "ex_secrets",
      source_url: "https://github.com/zemuldo/ex_secrets",
      homepage_url: "https://hexdocs.pm/ex_secrets/readme.html",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/zemuldo/ex_secrets"}
    ]
  end

  defp docs() do
    [
      source_url: "https://github.com/zemuldo/ex_secrets",
      source_ref: "main",
      main: "readme",
      logo: "logo.png",
      extras: ["README.md", "GUIDES.md", "CHANGELOG.md", "LICENSE"]
    ]
  end
end
