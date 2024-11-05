function [P] = Get_P(idxs, Graph, E)
%GET_P 计算过渡矩阵P
% P 为V*V * E 矩阵，P(i,e)=1, if 第i种起止点组合的估算路由包括链路e
    P = zeros( size(idxs,1) , E );
    
    for i = 1:size(idxs,1)
        s = idxs(i,1);
        d = idxs(i,2);
        [~, ~, edgepath] = shortestpath(Graph, s, d);
        for k = 1:size(edgepath,2)
            e = edgepath(1,k);
            P(i, e) = 1;
        end
    
    end

end

