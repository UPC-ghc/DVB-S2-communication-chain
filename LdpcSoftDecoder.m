function [graph] = LdpcSoftDecoder(bits_rx, H, graph, noiseVar, numIt)
[M,N] = size(H);
it = 0;
decoded_bits = bits_rx;
Lci = (-2/noiseVar)*bits_rx;
% first step: 
% initialize the v_nodes
% for i=1:N
%     graph.v_nodes(i).msg = Lci;
% end
% then communicate the msg to c_nodes
for i=1:N
    c_nodes = graph.v_nodes(i).c_nodes; % c_nodes connected to a given v_node
    for j=1:length(c_nodes)
        idx = c_nodes(j).num; % get the global c_node index
        nums = [graph.c_nodes(idx).v_nodes(:).num];  % v_nodes connected the c_node
        for k=1:length(nums)
            % to get relative index of v_node with respect to c_node
            if nums(k) == i
                graph.c_nodes(idx).v_nodes(k).msg = Lci;
            end
        end
    end
end

while ((it < numIt) && (length(find(mod(decoded_bits*H',2))) ~= 0))
    % second step:
    % calculate the response of the c_nodes using Gallager formula 
    % (in the log domain)
    for i=1:M
        v_nodes = graph.c_nodes(i).v_nodes; % v_nodes connected to a given c_node
        sumPhi = sum(-log(tanh(abs([v_nodes(:).msg])/2)));
        for j=1:length(v_nodes)
            v_nodes_no_j = v_nodes;
            v_nodes_no_j(j) = []; 
            prodXi = prod(sign([v_nodes_no_j(:).msg]));
            idx = v_nodes(j).num;
            nums = [graph.v_nodes(idx).c_nodes(:).num]; % c_nodes connected the v_node
            alpha_j = -log(tanh(abs(v_nodes(j).msg)/2));
            Lrji = prodXi * (-log(tanh((sumPhi - alpha_j)/2)))
            for k=1:length(nums)
                % to get relative index of v_node with respect to c_node
                if nums(k) == i
                    graph.v_nodes(idx).c_nodes(k).msg = Lrji;
                end
            end
        end
    end

    % third step:
    % v_nodes take a decision based on the response from c_node and original
    % msg using a majoroty vote
    for i=1:N
        c_nodes = graph.v_nodes(i).c_nodes;
        softDecision = Lci + sum([c_nodes(:).msg]);
        for j=1:length(c_nodes)
            idx = c_nodes(j).num; % get the global c_node index
            nums = [graph.c_nodes(idx).v_nodes(:).num];  % v_nodes connected the c_node
            Lqij = softDecision - c_nodes(j).msg;
            for k=1:length(nums)
                % to get relative index of v_node with respect to c_node
                if nums(k) == i
                    graph.c_nodes(idx).v_nodes(k).msg = Lqij;
                end
            end
        end
        if softDecision < 0
            decoded_bits(i) = 1;
        else
            decoded_bits(i) = 0;
        end
    end
    it = it + 1;
end

end