defmodule Randex do
  use Application
  require Logger
  require Exutils
  @group "randex_workers"
  @group_full "randex_workers_full"

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :ok = :pg2.create(@group)
    :ok = :pg2.create(@group_full)
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

  defp randomize do
	<<a::32, b::32, c::32>> = :crypto.rand_bytes 12
	case :random.seed(a, b, c) do
		:undefined -> :ok
		{a,b,c} when (is_integer(a) and is_integer(b) and is_integer(c)) -> :ok
	end
  end

  defp add_new_worker do
    :ok = :supervisor.start_child( Randex.Supervisor, Supervisor.Spec.worker(Randex.Worker, [], [id: Exutils.makecharid, restart: :transient])) |> elem(0)
  end
  defp receive_ans(type) do
	len = length(:pg2.get_members(@group_full))
  	await = (len*len)
    receive do
  		{^type, res} -> res
  	after
		await -> add_new_worker
				 receive_ans(type)
  	end
  end

  #
  # public
  #

  # here do seed in this thread
  def shuffle(enum) when (is_list(enum) or is_map(enum)) do
	randomize
	Enum.shuffle(enum)
  end
  def uniform(int) when (is_integer(int) and (int > 0)) do
	randomize
	:random.uniform(int)
  end


  #	here call gen_servers
  def shuffle_call(enum) when (is_list(enum) or is_map(enum)) do
    case :pg2.get_members(@group) |> Enum.shuffle do
      [pid|_] -> 
      	send(pid, {:shuffle, self, enum})
        receive_ans(:shuffle)
      [] -> 
      	add_new_worker
        shuffle(enum)
    end
  end
  def uniform_call(int) when (is_integer(int) and (int > 0)) do
    case :pg2.get_members(@group) |> Enum.shuffle  do
      [pid|_] -> 
      	send(pid, {:uniform, self, int})
      	receive_ans(:uniform)
      [] -> 
      	add_new_worker
        uniform(int)
    end
  end

end
