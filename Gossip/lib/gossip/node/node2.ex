defmodule Gossip.Node2 do
    use GenServer

    @stop_range :math.pow(10, -10)
    
    def init(offset) do
        nodename = String.to_atom("Node_" <> to_string(offset))
        neighlist = String.to_atom("Neighbours_" <> to_string(offset))
        values = String.to_atom("Info_" <> to_string(offset))
        Agent.start_link(fn -> [] end, name: neighlist)
        Agent.start_link(fn -> { offset, 1 } end, name: values)
        { :ok, { :unstart, nodename, neighlist, values } }
    end

    def handle_call( _ , _, state) do
        { :unstart, nodename, neighlist, values } = state
        nums = length(Agent.get(neighlist, &(&1)))
        { :reply, { :ok }, { nums, nodename, { :unstart, neighlist, values } } }
    end 

    def handle_finish({ :unstart, neighlist, _ }, nums, nodename, from) do
        Agent.update(neighlist, &(Enum.filter(&1, fn node -> node != from end)))
        if nums == 1, do: manager_finish(nodename, neighlist)
    end
    def handle_finish({ pid, neighlist, _, _ }, nums, nodename, from) do
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
            { nums, nodename, { :unstart, neighlist, values } } -> 
                start(arg, nums, nodename, neighlist, values)
            _ -> handleMessage(arg, state)
        end
    end

    def start(arg, nums, nodename, neighlist, values) do
        { from, {fs, fw} } = arg
        #IO.puts Atom.to_string(nodename) <> " receives a message from " <> Atom.to_string(from)
        #IO.puts Atom.to_string(nodename) <> " starts to send message. It has #{nums} neighbours"
        pid = Task.async(Gossip.Node2, :sending, [ neighlist, values, nodename ])
        ratio = Agent.get_and_update(values, fn { s, w } -> { s/w , {s + fs, w + fw} } end)
        { :noreply, { nums, nodename, { pid, neighlist, values, ratio } } }
    end
    
    def handleMessage(arg, state) do
        { nums, nodename, offset } = state
        { from, {fs, fw} } = arg
        case offset do
            { pid, neighlist, values, last } ->
                #IO.puts Atom.to_string(nodename) <> " receives a message from " <> Atom.to_string(from)
                { s, w } = Agent.get_and_update(values, 
                fn { s, w } -> 
                    { { s, w } , {s + fs, w + fw} } 
                end)
                first = (s + fs)/(w + fw)
                second = s / w
                #IO.puts Atom.to_string(nodename) <> " has ratio " <> Float.to_string(second)
                change = get_change(first, second, last)
                if change < @stop_range do
                    #IO.puts Atom.to_string(nodename) <> ". It finishes"
                    send(:Manager, { :finished, nodename, :os.system_time(:millisecond), last })
                    info_Neigh(nodename, neighlist)
                    Task.shutdown(pid)
                    { :noreply, { nums, nodename, { :finish } } }
                else
                    { :noreply, { nums, nodename, { pid, neighlist, values, s/w } } }
                end
            { :finish } -> 
                { :noreply, { nums, nodename, { :finish } } }
        end
    end

    defp get_change(first, second, third) do
        avg = (first + second + third) / 3
        (abs(first - avg) + abs(second - avg) + abs(third - avg))/3
    end

    defp info_Neigh(nodename, neighlist) do
        Agent.get(neighlist, &(&1))
        |> Enum.each(&(GenServer.cast(&1, { :finish, nodename } )))
    end

    def sending(neighlist, values, nodename) do
        :timer.sleep(200)
        list = Agent.get(neighlist, &(&1))
        val = Agent.get_and_update(values, 
            fn { s, w } -> 
                { {s / 2, w / 2}, {s / 2, w / 2} } 
            end)
        if length(list) != 0 do
            Enum.random(list)
            |> GenServer.cast({ nodename, val })
        end
        sending(neighlist, values, nodename)
    end

end