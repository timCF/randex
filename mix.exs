defmodule Randex.Mixfile do
  use Mix.Project

  def project do
    [app: :randex,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications:  [  
                      :logger,
                      :exactor,
                      :exutils,
                      :sfmt
                    ],
     mod: {Randex, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:exactor, github: "sasa1977/exactor", tag: "0467f8100bc735405d597dbf94996195eb31e0b6", override: true},
      {:exutils, github: "timCF/exutils"},
      {:sfmt, github: "jj1bdx/sfmt-erlang"}
    ]
  end
end
