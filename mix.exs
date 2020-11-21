defmodule ScryD3.Mixfile do
  use Mix.Project

  def project do
    [
      app: :id3v2,
      version: "0.1.7",
      elixir: elixir(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      description: "ScryD3 tag header reading",
      package: package(),
      aliases: aliases()
    ]
  end

  def elixir(env) do
    case env do
      :docs -> "~> 1.2"
      _ -> "~> 1.2"
    end
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps(_) do
    [
      {:ex_doc, ">= 0.0.0", only: :docs},
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
      name: "id3v2",
      licenses: ["ZLIB"],
      maintainers: ["Cheezmeister"],
      links: %{
        GitHub: "https://github.com/Cheezmeister/elixir-id3v2",
        Hex: "https://hex.pm/packages/id3v2"
      }
    ]
  end
end
