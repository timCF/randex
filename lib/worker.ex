defmodule Randex.Worker do
	use ExActor.GenServer
	@group "randex_workers"
	@ttl 2 * 60 * 1000
	@buzz 3 * 60 * 1000

	defp maybe_randomize(stamp) do
		full_buzz = @ttl + :random.uniform(@buzz)
		case Exutils.makestamp do
			some when (some < (stamp + full_buzz)) -> stamp
			new_stamp ->
				<<a::32, b::32, c::32>> = :crypto.rand_bytes(12)
				:sfmt.seed(a,b,c)
				new_stamp
		end
	end

	#
	#	callbacks
	#

	definit do
		:ok = :pg2.join(@group, self)
		{:ok, maybe_randomize(0)}
	end
	definfo subj = {_,_,_}, state: stamp do
		handle_answer(subj)
		receive do
			subj = {_, _, _} -> handle_answer(subj)
		after
			1 -> :ok
		end
		{:noreply, maybe_randomize(stamp)}
	end
	
	#
	#	priv
	#

	defp handle_answer(subj = {:shuffle, sender, enum}), do: send(sender, {subj, mt_shuffle(enum)})
	defp handle_answer(subj = {:uniform_int, sender, int}), do: send(sender, {subj, :sfmt.uniform(int)})
	defp handle_answer(subj = {:uniform_float, sender, nil}), do: send(sender, {subj, :sfmt.uniform})

	defp mt_shuffle(some), do: Enum.to_list(some) |> mt_shuffle_proc([])
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

end