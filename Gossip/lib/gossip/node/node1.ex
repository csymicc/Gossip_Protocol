defmodule Gossip.Node1 do
    use GenServer

    @stop_times 10

    def init([no, list]) do
        nodename = String.to_atom("Node_" <> to_string(no))
        neighlist = String.to_atom("Neighbours_" <> to_string(no))
        Agent.start_link(fn -> list end, name: neighlist)
        { :ok, { length(list), nodename, { :unstart, neighlist } } }
    end
    def init(offset) do
        nodename = String.to_atom("Node_" <> to_string(offset))
        neighlist = String.to_atom("Neighbours_" <> to_string(offset))
        Agent.start_link(fn -> [] end, name: neighlist)
        { :ok, { :unstart, nodename, neighlist } }
    end

    def handle_call( _ , _, state) do
        { :unstart, nodename, neighlist } = state
        nums = length(Agent.get(neighlist, &(&1)))
        { :reply, { :ok }, { nums, nodename, { :unstart, neighlist } } }
    end 

    def handle_finish({ :unstart, neighlist }, nums, nodename, from) do
        Agent.update(neighlist, &(Enum.filter(&1, fn node -> node != from end)))
        if nums == 1, do: manager_finish(nodename, neighlist)
    end
    def handle_finish({ pid, neighlist, _ }, nums, nodename, from) do
        Agent.update(neighlist, &(Enum.filter(&1, fn node -> node != from end)))
        if nums == 1 do
            Task.shutdown(pid)
            manager_finish(nodename, neighlist)
        end
    end
    defp manager_finish(nodename, neighlist) do
        #IO.puts Atom.to_string(nodename) <> "   " <> inspect Agent.get(neighlist, &(&1))
        #IO.puts Atom.to_string(nodename) <> "'s neighbours are all finished. It cannot be finished"
        send(:Manager, { :unfinished, nodename, :os.system_time(:millisecond) })
        info_Neigh(nodename, neighlist)
    end

    def handle_cast({ :finish, from }, state) do
        { nums, nodename, offset } = state
        if offset != { :finish } do
            handle_finish(offset, nums, nodename, from)
        end
        { :noreply, { nums - 1, nodename, offset } }
    end
    
    def handle_cast(arg, state) do
        case state do
            { nums, nodename, { :unstart, neighlist } } -> start(arg, nums, nodename, neighlist)
            _ -> handleMessage(arg, state)
        end
    end

    def start(arg, nums, nodename, neighlist) do
        #IO.puts Atom.to_string(nodename) <> " receives a message from " <> Atom.to_string(arg)
        #IO.puts Atom.to_string(nodename) <> " starts to send message. It has #{nums} neighbours"
        pid = Task.async(Gossip.Node1, :sending, [ neighlist, nodename ])
        { :noreply, { nums, nodename, { pid, neighlist, 1 } } }
    end
    
    def handleMessage(arg, state) do
        { nums, nodename, offset } = state
        case offset do
            { pid, neighlist, @stop_times } ->
                #IO.puts Atom.to_string(nodename) <> " receives a message from " <> Atom.to_string(arg) <> ". It finishes"
                send(:Manager, { :finished, nodename, :os.system_time(:millisecond) })
                info_Neigh(nodename, neighlist)
                Task.shutdown(pid)
                { :noreply, { nums, nodename, { :finish } } }
            { pid, neighlist, times } ->
                #IO.puts Atom.to_string(nodename) <> " receives a message from " <> Atom.to_string(arg)
                { :noreply, { nums, nodename, { pid, neighlist, times + 1 } } }
            { :finish } -> 
                { :noreply, { nums, nodename, { :finish } } }
        end
    end

    defp info_Neigh(nodename, neighlist) do
        Agent.get(neighlist, &(&1))
        |> Enum.each(&(GenServer.cast(&1, { :finish, nodename } )))
    end

    def sending(neighlist, nodename) do
        :timer.sleep(500)
        list = Agent.get(neighlist, &(&1))
        if length(list) != 0 do
            Enum.random(list)
            |> GenServer.cast(nodename)
        end
        sending(neighlist, nodename)
    end 

end