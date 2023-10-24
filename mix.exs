defmodule ExSecrets.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_secrets,
      version: "0.1.6",
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        # The main page in the docs
        main: "readme",
        logo: "logo.png",
        extras: ["README.md", "GUIDES.md", "CHANGELOG.md", "LICENSE"]
      ]
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
      # Dependecies.
      {:httpoison, "~> 1.8"},
      {:poison, "~> 3.1"},
      {:joken, "~> 2.6"},

      # Testing and Documentation
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
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
end
