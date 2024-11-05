function [Graph_now, P_matrix_new, prob] = Update_Graph_P_2(g_use_result, g_ini, g_now, idxs, P_matrix_ini, Graph_0)
% 迭代过程中，评估带宽占用情况->改变边权重->改变默认最短路由P
% Update_Graph_P_1函数：8.9.2022修改
% Update_Graph_P_2函数：9.01.2022修改，为了适应WS拓扑，修改函数接口

% 注意：传入的变量g_now，是本轮迭代开始时的带宽，没有减去本轮求解结果使用的带宽！！！
% 计算prob时，不能使用g_now，应使用考虑本轮带宽使用情况后的结果g_evaluat
g_evaluat = g_now - g_use_result;

% 评估本次迭代后，所有链路的利用率
theta_edge = (g_ini - g_now + g_use_result) ./ g_ini;    % E*1 vector
% 根据利用率，更新边权重, 重新计算路由矩阵P
graph_weights_now = weight_func(theta_edge);
% Graph_now = graph(graph_s,graph_t,graph_weights_now);       % 使用新的权重生成拓扑
% [~,E] = size(graph_s);              % 链路总数E
% P_matrix_new = Get_P(idxs, Graph_now, E);

Graph_now = Graph_0;
Graph_now.Edges.Weight = graph_weights_now;     % 更新拓扑的边权重
[~,E] = size(theta_edge);
P_matrix_new = Get_P(idxs, Graph_now, E);

% 根据每个起止点i的新旧路径带宽比，计算prob，I*1 vector
V = sqrt(size(P_matrix_ini, 1));
prob = zeros(V^2, 1);
band_0 = 0.1 * ones(V^2, 1);        % 一条path上的最小带宽
band_new = 0.1 * ones(V^2, 1);

for i = 1:V^2
    use_edges_0 = find(P_matrix_ini(i,:));
    bands = [];
    for ee = 1:size(use_edges_0,2)
        bands = [ bands; g_evaluat(use_edges_0(ee)) ];
        band_0(i) = min(bands);
    end

    use_edges_n = find(P_matrix_new(i,:));
    bands = [];
    for ee = 1:size(use_edges_n,2)
        bands = [ bands; g_evaluat(use_edges_n(ee)) ];
        band_new(i) = min(bands);
    end
    
    prob(i) = band_new(i) / (band_0(i)+band_new(i));        % prob(i)为：起止点i选择新路由的概率

end



% P_combine = cat(2, P_matrix_ini, P_matrix_now);     % 横向拼接
% 
% % 请求依概率prob选用更新后的默认路由矩阵P
% % use_new_P = randsrc(K, 1, [0 1; 1-prob prob]);
% 
% % 随机选择一些（总数固定）请求，使用新路由矩阵P
% change_id = randperm(K, ceil(K*prob));
% use_new_P = zeros(K,1);
% for nn = 1:size(change_id,2)
%     use_new_P(change_id(nn)) = 1;
% end
% 
% choice = zeros(2*E, E, K);
% for kk = 1:K
%     if use_new_P(kk) == 1
%         choice(:,:,kk) = cat(1, zeros(E,E), eye(E));    % 选用新的路由矩阵P_now
%     else
%         choice(:,:,kk) = cat(1, eye(E), zeros(E,E));    % 选用初始路由矩阵P_ini
%     end
% end

end

