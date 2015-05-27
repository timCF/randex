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

  defp randomize do
	<<a::32, b::32, c::32>> = :crypto.rand_bytes 12
	case :random.seed(a, b, c) do
		:undefined -> :ok
		{a,b,c} when (is_integer(a) and is_integer(b) and is_integer(c)) -> :ok
	end
  end

  defp add_new_worker, do: :ok = :supervisor.start_child( Randex.Supervisor, Supervisor.Spec.worker(Randex.Worker, [], [id: Exutils.makecharid, restart: :transient])) |> elem(0)
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

  defp mt_randomize do
    <<a::32, b::32, c::32>> = :crypto.rand_bytes 12
    :sfmt.seed(a,b,c)
  end

  defp mt_shuffle_proc([], res), do: res
  defp mt_shuffle_proc(lst, res_lst) do
    index = :sfmt.uniform(length lst) - 1
    %{lst: new_lst, res: new_res} = Enum.reduce(lst, %{lst: [], res: nil, counter: 0},
      fn 
      el, resmap = %{counter: counter} when (counter == index) -> Map.update!(resmap, :res, fn(nil) -> el end) |> Map.update!(:counter, &(&1+1))
      el, resmap = %{} -> Map.update!(resmap, :lst, &([el|&1])) |> Map.update!(:counter, &(&1+1))
      end)
    mt_shuffle_proc(new_lst, [new_res|res_lst])
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

  # here use sfmt
  def mt_hard_uniform(int) when is_integer(int) do
    mt_randomize
    :sfmt.uniform(int)
  end
  def mt_hard_uniform do
    mt_randomize
    :sfmt.uniform
  end
  def mt_hard_shuffle(some) do 
    mt_randomize
    Enum.to_list(some) |> mt_shuffle_proc([])
  end

  def mt_uniform(int) when is_integer(int), do: :sfmt.uniform(int)
  def mt_uniform, do: :sfmt.uniform
  def mt_shuffle(some), do: Enum.to_list(some) |> mt_shuffle_proc([])

  #	here call gen_servers
  def shuffle_call(enum) when (is_list(enum) or is_map(enum)) do
    subj = {:shuffle, self, enum}
    get_worker |> send(subj)
    receive_ans(subj)
  end
  def uniform_call(int) when (is_integer(int) and (int > 0)) do
    subj = {:uniform_int, self, int}
    get_worker |> send(subj)
    receive_ans(subj)
  end
  def uniform_call do
    subj = {:uniform_float, self, nil}
    get_worker |> send(subj)
    receive_ans(subj)
  end

  #miXed generator
  def x_uniform do
    case :sfmt.uniform do
      mt when (mt > 0.98) ->  mt_randomize
                              :sfmt.uniform
      mt when (mt >= 0.5) ->  :sfmt.uniform
      na when (na < 0.02) ->  randomize
                              :random.uniform
      na when (na < 0.5)  ->  :random.uniform
    end
  end

  def x_uniform(int) when is_integer(int) do
    case :sfmt.uniform do
      mt when (mt > 0.98) ->  mt_randomize
                              :sfmt.uniform(int)
      mt when (mt >= 0.5) ->  :sfmt.uniform(int)
      na when (na < 0.02) ->  randomize
                              :random.uniform(int)
      na when (na < 0.5)  ->  :random.uniform(int)
    end
  end

  def x_shuffle(lst) do
    case :sfmt.uniform do
      mt when (mt > 0.98) ->  mt_randomize
                              mt_shuffle(lst)
      mt when (mt >= 0.5) ->  mt_shuffle(lst)
      na when (na < 0.02) ->  randomize
                              Enum.shuffle(lst)
      na when (na < 0.5)  ->  Enum.shuffle(lst)
    end
  end

end
