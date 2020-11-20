defmodule UeberauthTwitch.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :ueberauth_twitch,
      version: @version,
      package: package(),
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/talk2MeGooseman/ueberauth_twitch",
      homepage_url: "https://github.com/talk2MeGooseman/ueberauth_twitch",
      description: description(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.4"},

      # dev/test only dependencies
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.13", only: :test},

      # docs dependencies
      {:earmark, ">= 1.4.0", only: :dev},
      {:ex_doc, ">= 0.22.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Twitch to authenticate your users."
  end

  defp package do
    [
      name: "ueberauth_twitch",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Erik Guzman"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/talk2MeGooseman/ueberauth_twitch"}
    ]
  end

  defp aliases do
    [
      lint: ["format", "credo"]
    ]
  end
end
