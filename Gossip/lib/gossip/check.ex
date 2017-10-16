defmodule Check do
    use GenServer

    def init(k) do
        {:ok, pid} = Agent.start_link(fn -> 1 end, name: :s)
        IO.puts inspect pid
    end


end