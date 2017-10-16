defmodule Gossip.Manager.Fail do
    
    def start(numNodes, topology, algorithm, fail_interval) do
        Process.register(self(), :Manager)
        Agent.start_link(fn -> [] end, name: :res)
        Enum.map(0..numNodes - 1, &(start_node(&1, algorithm)))
        |> Gossip.Topology.init_Topology(topology, numNodes) 
        |> start_algorithm(numNodes, algorithm, fail_interval)
    end

    def start_node(no, algorithm) do
        nodename = String.to_atom("Node_" <> to_string(no))
        case algorithm do
            0 -> { no, GenServer.start(Gossip.Node1, no, name: nodename) }
            1 -> { no, GenServer.start(Gossip.Node2, no, name: nodename) }
        end
    end

    def start_algorithm(nodelist, numNodes, algorithm, fail_interval) do
        nodelist |> Enum.each(&(GenServer.call(&1, :initalize)))
        start_node = nodelist |> Enum.random
        start_time = :os.system_time(:millisecond);
        case algorithm do
            0 -> GenServer.cast(start_node, :Manager)
            1 -> GenServer.cast(start_node, { :Manager, { 0, 0 } })
        end
        spawn_link(Gossip.Manager.Fail, :fail_node, [ nodelist, algorithm, fail_interval ])
        maintain(nodelist, numNodes, start_time)
    end

    defp maintain(nodelist , 0, start_time ), do: show_result(nodelist, start_time)
    defp maintain(nodelist, unfinish_num, start_time) do
        receive do
            { :finished, nodename, finish_time } ->
                Agent.update(:res, &( &1 ++ [{ nodename, finish_time - start_time}]))
            { :finished, nodename, finish_time, ratio } ->
                Agent.update(:res, &( &1 ++ [{ nodename, finish_time - start_time, ratio}]))
            _ -> { :ok }
        end
        maintain(nodelist, unfinish_num - 1, start_time)
    end

    def fail_node(nodelist, algorithm, fail_interval) do
        node = Enum.random(nodelist)
        #IO.puts Atom.to_string(node) <> " fails and will reboot"
        no = Atom.to_string(node) |> String.replace("Node_", "") |> String.to_integer
        neighname = String.to_atom("Neighbours_" <> to_string(no))
        neighlist = neighname |> Agent.get(&(&1))
        GenServer.stop(node)
        :timer.sleep(fail_interval)
        case algorithm do
            0 -> 
                GenServer.start(Gossip.Node1, [ no, neighlist ], name: node)
                GenServer.cast(node, :Manager)
            1 -> 
                GenServer.start(Gossip.Node2, [ no, neighlist ], name: node)
                GenServer.cast(node, { :Manager, { 0, 0 } })
        end
        fail_node(nodelist, algorithm, fail_interval)
    end

    defp show_result(nodelist, start_time) do
        lens = Agent.get(:res, &(&1)) |> length
        time = :os.system_time(:millisecond) - start_time
        IO.puts time
        IO.puts lens / length(nodelist) * 100
        #Enum.each(Agent.get(:res, &(&1)), fn res -> IO.puts inspect res end)
    end

end