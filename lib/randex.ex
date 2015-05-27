defmodule Randex do
  use Application
  require Logger
  require Exutils
  use Silverb
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

  #
  # public, here we call gen servers
  #

  def shuffle(some), do: Enum.to_list(some) |> shuffle_proc([])
  def uniform(int) when (is_integer(int) and (int > 0)), do: uniform_priv(int)
  def uniform do
    subj = {:uniform_float, self, nil}
    get_worker |> send(subj)
    receive_ans(subj)
  end

  #
  # some priv funcs
  #

  defp uniform_priv(int) do
    subj = {:uniform_int, self, int}
    get_worker |> send(subj)
    receive_ans(subj)
  end

  defp shuffle_proc([], res), do: res
  defp shuffle_proc(lst, res_lst) do
    index = uniform_priv(length lst) - 1
    %{lst: new_lst, res: new_res} = Enum.reduce(lst, %{lst: [], res: nil, counter: 0},
      fn 
      el, resmap = %{counter: counter} when (counter == index) -> Map.update!(resmap, :res, fn(nil) -> el end) |> Map.update!(:counter, &(&1+1))
      el, resmap = %{} -> Map.update!(resmap, :lst, &([el|&1])) |> Map.update!(:counter, &(&1+1))
      end)
    shuffle_proc(new_lst, [new_res|res_lst])
  end


  defp get_worker do
    case :pg2.get_members(@group) |> Enum.shuffle do
      [pid|_] ->  pid
      [] -> add_new_worker
            get_worker
    end
  end
  defp receive_ans(subj) do
    len = length(:pg2.get_members(@group))
    await = (len*len)
    receive do
      {^subj, res} -> res
    after
      await ->  add_new_worker
                receive_ans(subj)
    end
  end

  defp add_new_worker, do: :ok = :supervisor.start_child( Randex.Supervisor, Supervisor.Spec.worker(Randex.Worker, [], [id: Exutils.makecharid, restart: :transient])) |> elem(0)

end
