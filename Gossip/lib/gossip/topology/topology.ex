defmodule Gossip.Topology do

    def init_Topology(nodelist, topology, numNodes) do
        case topology do
            0 -> Enum.map(nodelist, &(full(&1, numNodes)))
            1 -> Enum.map(nodelist, &(two_D(&1, numNodes)))
            2 -> Enum.map(nodelist, &(line(&1, numNodes)))
            3 -> Enum.map(nodelist, &(two_D(&1, numNodes))) |> imp_two_D
        end
    end

    defp fill_in_data(neighbour_list, no) do
        listname = String.to_atom("Neighbours_" <> to_string(no))
        #IO.puts no
        #IO.puts inspect neighbour_list
        Agent.update(listname, fn _ -> neighbour_list end)
        String.to_atom("Node_" <> to_string(no))
    end

    defp full( { no, _ }, numNodes) do
        Enum.to_list(0..numNodes - 1)
        |> Enum.filter(fn node -> node != no end)
        |> Enum.map(&(String.to_atom("Node_" <> to_string(&1))))
        |> fill_in_data(no)
    end

    defp two_D( { no, _ }, numNodes ) do
        r = round(:math.sqrt(numNodes))
        [ {-1, 0}, {0, 1}, {1, 0}, {0, -1} ] 
        |> Enum.map(fn { x, y } -> { div(no, r) + x, rem(no, r) + y } end)
        |> Enum.filter(fn { x, y } -> x >= 0 && x < r && y >= 0 && y < r end)
        |> Enum.map(fn { x, y } -> x * r + y end)
        |> Enum.map(&(String.to_atom("Node_" <> to_string(&1))))
        |> fill_in_data(no)
    end

    defp line( { no, _ }, numNodes ) do
        cond do
            no == 0 -> 
                [ String.to_atom("Node_1") ]
            no == numNodes - 1 -> 
                [ String.to_atom("Node_" <> to_string(numNodes - 2)) ]
            :true -> 
                [ String.to_atom("Node_" <> to_string(no - 1)),
                String.to_atom("Node_" <> to_string(no + 1)) ]
        end
        |> fill_in_data(no)
    end

    defp imp_two_D(nodelist) do
        init_imp_two_D(nodelist)
        #Enum.map(nodelist, &(Atom.to_string(&1)))
        #|> Enum.map(&(String.replace(&1, "Node_", "Neighbours_")))
        #|> Enum.map(&(String.to_atom(&1)))
        #|> Enum.each(&(IO.puts Atom.to_string(&1) <> inspect Agent.get(&1, fn a -> a end))) 
        nodelist
    end

    defp init_imp_two_D(list) when length(list) < 3, do: { :ok }
    defp init_imp_two_D(list) do
        [ node1 | tail ] = list
        neighbour1 = Atom.to_string(node1) |> String.replace("Node_", "Neighbours_") |> String.to_atom
        list = Agent.get(neighbour1, &(&1))
        node2 = Enum.filter(tail, &(!Enum.any?(list, fn n -> &1 == n end))) |> Enum.random
        neighbour2 = Atom.to_string(node2) |> String.replace("Node_", "Neighbours_") |> String.to_atom
        Agent.update(neighbour1, fn list -> list ++ [ node2 ] end)
        Agent.update(neighbour2, fn list -> list ++ [ node1 ] end)
        init_imp_two_D(Enum.filter(tail, &(&1 != node2)))
    end
    
end