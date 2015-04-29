defmodule Randex do
  use Application
  require Logger
  require Exutils
  @group "randex_workers"

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :ok = :pg2.create(@group)
    children = [
      # Define workers and child supervisors to be supervised
      # worker(Randex.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Randex.Supervisor]
    Supervisor.start_link(children, opts)
  end
  def stop(reason) do
    Logger.error("#{__MODULE__} : ERLANG HALT !!#{inspect reason}!! ERLANG HALT") |> Exutils.safe
    :erlang.halt
  end

  defp add_new_worker do
    :ok = :supervisor.start_child( Randex.Supervisor, Supervisor.Spec.worker(Randex.Worker, [], [id: Exutils.makecharid, restart: :transient])) |> elem(0)
  end

  #
  # public
  #

  def shuffle(enum) when (is_list(enum) or is_map(enum)) do
    case :pg2.get_members(@group) |> Enum.shuffle do
      [pid|_] -> Randex.Worker.shuffle(pid,enum)
      [] -> add_new_worker
            shuffle(enum)
    end
  end
  def uniform(int) when (is_integer(int) and (int > 0)) do
    case :pg2.get_members(@group) |> Enum.shuffle  do
      [pid|_] -> Randex.Worker.uniform(pid,int)
      [] -> add_new_worker
            uniform(int)
    end
  end

end
