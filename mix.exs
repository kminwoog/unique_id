defmodule SnowflakeIdx.MixProject do
  use Mix.Project

  def project do
    [
      app: :snowflake_idx,
      version: "1.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "snowflake_idx",
      source_url: "https://github.com/kminwoog/snowflake_idx"
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp description() do
    "A rapid, easy to use Snowflake ID Generator."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "snowflake_idx",
      # These are the default files included in the package
      files: ["lib", "test", "config", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["kim min woog"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kminwoog/snowflake_idx"}
    ]
  end
end
