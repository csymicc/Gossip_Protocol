defmodule Project2.CLI do
    
    def main([numNodes, topology, algorithm]) do
        n = String.to_integer(numNodes);
        t = case topology do
                "full" -> 0
                "2D" -> 1
                "line" -> 2
                "imp2D" -> 3
                _ -> IO.puts "input wrong"
            end
        a = case algorithm do
                "gossip" -> 0
                "push-sum" -> 1
                _ -> IO.puts "input wrong"
            end
        if n < 1 || ((t == 1 || t == 3) && n < 4) do
            IO.puts "Not enough nodes, please "
        end
        if t == 1 || t == 3 do
            root = round(Float.floor(:math.sqrt(n)))
            n = root * root
        end
        Gossip.Manager.start(n, t, a)
    end
    def main([numNodes, topology, algorithm, fail_interval]) do
        n = String.to_integer(numNodes);
        t = case topology do
                "full" -> 0
                "2D" -> 1
                "line" -> 2
                "imp2D" -> 3
                _ -> IO.puts "input wrong"
            end
        a = case algorithm do
                "gossip" -> 0
                "push-sum" -> 1
                _ -> IO.puts "input wrong"
            end
        if n < 1 || ((t == 1 || t == 3) && n < 4) do
            IO.puts "Not enough nodes, please "
        end
        if t == 1 || t == 3 do
            root = round(Float.floor(:math.sqrt(n)))
            n = root * root
        end
        
        Gossip.Manager.Fail.start(n, t, a, String.to_integer(fail_interval))
    end

end