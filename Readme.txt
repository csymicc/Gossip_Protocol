Individual work

In my program, situation where each node ends is the same as that described in Proj2.pdf. 

Node in my program will send one message to its neighbors during each interval. The interval I choose for node in gossip algorithm is 500ms, and that in path-sum is 200ms (to speed up convergence). The reason I set an interval between sending two messages is full network topology will cause sending of enormous messages at the beginning and will cause CPU usage reach 100%. This will introduce large process delay and will cause result different from real network situation.
In both parts, I measured the finish time, which is from the sending of first message to the finish of last node. I used it to measure the convergence time for each topology. I tested the finish time in different numbers of nodes.

I can run 5000 nodes by using full network topology in both gossip and push-sum. More nodes will cause memory problem.

I can run more than 20000 nodes in my computer by using 2D and imp2D network topology in both gossip and push-sum after shortening the interval between sending two messages to 50ms. Time for 20000 nodes by using imp2D topology and gossip algorithm takes only 4.3s.

I can get result from 10000 nodes using my computer after increasing the stop condition for each node from 10 to 30. In original program, i can only get a result from 100 nodes by using Line topology because using line topology has a high probability that message transfer ends somewhere and other nodes cannot even receive one message. 
For more information, please see Report.pdf and Report-Bonus.pdf