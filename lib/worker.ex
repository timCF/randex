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
		:ok = :pg2.join("randex_workers_full", self)
		{:ok, maybe_randomize(0)}
	end
	definfo {command, sender, subj}, state: stamp do
		:ok = :pg2.leave(@group, self)
		case command do
			:shuffle -> send(sender, {:shuffle, Enum.shuffle(subj)})
			:uniform -> send(sender, {:uniform, :random.uniform(subj)})
		end 
		receive_and_handle_queue
		:ok = :pg2.join(@group, self)
		{:noreply, maybe_randomize(stamp)}
	end
	
	#
	#	priv
	#

	defp receive_and_handle_queue do
		receive do
			{:shuffle, sender, subj} -> 
				send(sender, {:shuffle, Enum.shuffle(subj)})
				receive_and_handle_queue
			{:uniform, sender, subj} -> 
				send(sender, {:uniform, :random.uniform(subj)})
				receive_and_handle_queue
		after
			1 -> :ok
		end
	end

end