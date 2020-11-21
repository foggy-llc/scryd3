defmodule ScryD3.Mixfile do
  use Mix.Project

  def project do
    [
      app: :scryd3,
      version: "0.2.0",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      description: "ScryD3 tag header reading",
      package: package(),
      aliases: aliases(),
      source_url: "https://gitea.foggy.llc/foggy.llc/scryd3"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp deps(_) do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases() do
    [
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end

  defp package do
    [
      name: "scryd3",
      licenses: ["ZLIB", "AGPL-3.0-or-later"],
      maintainers: ["foggy"],
      links: %{
        Gitea: "https://gitea.foggy.llc/foggy.llc/scryd3",
        Hex: "https://hex.pm/packages/scryd3"
      }
    ]
  end
end
