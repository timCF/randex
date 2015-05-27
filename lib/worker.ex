defmodule Randex.Worker do
	use ExActor.GenServer
	@group "randex_workers"
	@ttl 1 * 60 * 1000
	@buzz 2 * 60 * 1000

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

	defp handle_answer(subj = {:uniform_int, sender, int}), do: send(sender, {subj, :sfmt.uniform(int)})
	defp handle_answer(subj = {:uniform_float, sender, nil}), do: send(sender, {subj, :sfmt.uniform})

end