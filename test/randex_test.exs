defmodule RandexTest do
  use ExUnit.Case

  @num 1000

  @tag timeout: 300000
  test "mt shuffle" do
    {time, res} = :timer.tc fn() -> Enum.all?(1..100, 
            fn(_) ->
              r1 = Randex.shuffle(1..@num)
              r2 = Randex.shuffle(1..@num)
              #true = (r1 != r2)
              true = (Enum.to_list(1..@num) == Enum.sort(r1))
              true = (Enum.to_list(1..@num) == Enum.sort(r2))
            end)
          end
    IO.puts "mt shuffle #{time}"
    assert res
  end

  @tag timeout: 300000
  test "mt &uniform/0" do
    {time, res} = :timer.tc fn() -> Enum.all?(1..100, 
            fn(_) ->
              res = Randex.uniform
              true = (res > 0) and (res < 1)
            end)
          end
    IO.puts "mt &uniform/0 #{time}"
    assert res
  end

  @tag timeout: 300000
  test "mt &uniform/1" do
    {time, res} = :timer.tc fn() -> Enum.all?(1..100, 
            fn(n) ->
              res = Randex.uniform(n)
              true = (res > 0) and (res <= n)
            end)
          end
    IO.puts "mt &uniform/0 #{time}"
    assert res
  end

end
