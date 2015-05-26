defmodule RandexTest do
  use ExUnit.Case

  #@tag timeout: :timer.seconds(300)
  #test "agressive parallel calls" do
	#lst = Enum.to_list(1..10000)
  	#
  	#	to start some workers
  	#
  #	Exutils.pmap_lim(1..1000, 1, 250, &(Randex.uniform_call(&1)))
  	#
  	#	to start some workers
  	#
	#Enum.each([1000,10000], 
	#	fn(elems) ->
	#	  	{time1, _} = :timer.tc(fn() -> Exutils.pmap_lim(1..elems, 1, 250, &(Randex.uniform_call(&1))) end)
	#	  	{time2, _} = :timer.tc(fn() -> Exutils.pmap_lim(1..elems, 1, 250, &(Randex.uniform(&1))) end)
	#	  	IO.puts "pmap #{elems} : uniform_call #{time1 / 1000000}sec / uniform #{time2 / 1000000}sec"
	#	  	{time1, _} = :timer.tc(fn() -> Exutils.pmap_lim(1..elems, 1, 250, &(Randex.shuffle_call([&1|lst]))) end)
	#	  	{time2, _} = :timer.tc(fn() -> Exutils.pmap_lim(1..elems, 1, 250, &(Randex.shuffle([&1|lst]))) end)
	#	  	IO.puts "pmap #{elems} : shuffle_call #{time1 / 1000000}sec / shuffle #{time2 / 1000000}sec"
	#	end)

  #  assert 1+1 == 2
  #end

  test "mt" do
    res = Enum.all?(1..100, 
            fn(_) ->
              r1 = Randex.mt_shuffle(1..100)
              r2 = Randex.mt_shuffle(1..100)
              true = (r1 != r2)
              true = (Enum.to_list(1..100) == Enum.sort(r1))
              true = (Enum.to_list(1..100) == Enum.sort(r2))
            end)
    assert res
  end

  test "x" do
    res = Enum.all?(1..100, 
            fn(_) ->
              r1 = Randex.x_shuffle(1..100)
              r2 = Randex.x_shuffle(1..100)
              true = (r1 != r2)
              true = (Enum.to_list(1..100) == Enum.sort(r1))
              true = (Enum.to_list(1..100) == Enum.sort(r2))
            end)
    assert res
  end

end
