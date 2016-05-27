defmodule TapEx.Mixfile do
  use Mix.Project

  def project do
    [app: :tap_ex,
     version: "0.0.2",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [ applications: [
        :logger,
        :tunctl
      ]
    ]
  end

  defp deps do
    [ {:tunctl, git: "https://github.com/msantos/tunctl.git"}
    ]
  end
end
