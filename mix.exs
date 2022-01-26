defmodule Borsh.MixProject do
  use Mix.Project

  def project do
    [
      app: :borsh,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Elixir implementation of the BORSH binary serializer.
    """
  end

  defp package do
    [
      maintainers: ["Alex Filatov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alexfilatov/borsh",
        "Docs" => "https://hexdocs.pm/borsh"
      }
    ]
  end
end
