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
  @num 5

  @tag timeout: 300000
  test "mt" do
    {time, res} = :timer.tc fn() -> Enum.all?(1..100, 
            fn(_) ->
              r1 = Randex.mt_shuffle(1..@num)
              r2 = Randex.mt_shuffle(1..@num)
              #true = (r1 != r2)
              true = (Enum.to_list(1..@num) == Enum.sort(r1))
              true = (Enum.to_list(1..@num) == Enum.sort(r2))
            end)
          end
    IO.puts "pure mt #{time}"
    assert res
  end

  @tag timeout: 300000
  test "mt hard_shuffle" do
    {time, res} = :timer.tc fn() -> Enum.all?(1..100, 
            fn(_) ->
              r1 = Randex.mt_hard_shuffle(1..@num)
              r2 = Randex.mt_hard_shuffle(1..@num)
              #true = (r1 != r2)
              true = (Enum.to_list(1..@num) == Enum.sort(r1))
              true = (Enum.to_list(1..@num) == Enum.sort(r2))
            end)
          end
    IO.puts "hard_mt #{time}"
    assert res
  end

  @tag timeout: 300000
  test "mt shuffle_call" do
    {time, res} = :timer.tc fn() -> Enum.all?(1..100, 
            fn(_) ->
              r1 = Randex.shuffle_call(1..@num)
              r2 = Randex.shuffle_call(1..@num)
              #true = (r1 != r2)
              true = (Enum.to_list(1..@num) == Enum.sort(r1))
              true = (Enum.to_list(1..@num) == Enum.sort(r2))
            end)
          end
    IO.puts "mt shuffle_call #{time}"
    assert res
  end

  #test "x" do
  #  res = Enum.all?(1..100, 
  #          fn(_) ->
  #            r1 = Randex.x_shuffle(1..100)
  #            r2 = Randex.x_shuffle(1..100)
  #            true = (r1 != r2)
  #            true = (Enum.to_list(1..100) == Enum.sort(r1))
  #            true = (Enum.to_list(1..100) == Enum.sort(r2))
  #          end)
  #  assert res
  #end

end
