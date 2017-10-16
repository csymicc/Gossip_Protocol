defmodule Project2Test do
  use ExUnit.Case
  doctest Gossip.Manager

  test "greets the world" do
    result = computeAVG([ 121, 0, 0 ], 10, 0)
    IO.puts(result/10)
  end

  test "greets the" do
    result = computeAVG([ 121, 1, 0 ], 10, 0)
    IO.puts(result/10)
  end

  test "greets" do
    result = computeAVG([ 121, 2, 0 ], 10, 0)
    IO.puts(result/10)
  end

  def computeAVG( _ , 0, result), do: result
  def computeAVG(args, n, result) do
    pid = spawn(Gossip.Manager, :start, args)
    
    Task.shutdown(task)
    computeAVG(args, n - 1, r + result)
  end

end
