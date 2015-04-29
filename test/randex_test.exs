defmodule RandexTest do
  use ExUnit.Case

  @tag timeout: :timer.seconds(300)
  test "agressive parallel calls" do
  	:observer.start
    assert 1000000 == Exutils.pmap_lim(1..1000000, 1, 250, &(Randex.uniform(&1))) |> length()
  end
end
