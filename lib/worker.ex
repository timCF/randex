defmodule Randex.Worker do
	use ExActor.GenServer
	@group "randex_workers"
	@ttl 2 * 60 * 1000
	@buzz 3 * 60 * 1000
	defp timeout, do: @ttl + :random.uniform(@buzz)
	defp maybe_randomize(stamp) do
		full_buzz = timeout
		case Exutils.makestamp do
			some when (some < (stamp + full_buzz)) -> stamp
			new_stamp ->
				<<a::32, b::32, c::32>> = :crypto.rand_bytes 12
				case :random.seed(a, b, c) do
					:undefined -> :ok
					{a,b,c} when (is_integer(a) and is_integer(b) and is_integer(c)) -> :ok
				end
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
	defcall shuffle(enum), state: stamp do
		:ok = :pg2.leave(@group, self)
		res = {:reply, Enum.shuffle(enum), maybe_randomize(stamp)}
		:ok = :pg2.join(@group, self)
		res
	end
	defcall uniform(int), state: stamp do
		:ok = :pg2.leave(@group, self)
		res = {:reply, :random.uniform(int), maybe_randomize(stamp)}
		:ok = :pg2.join(@group, self)
		res
	end

end