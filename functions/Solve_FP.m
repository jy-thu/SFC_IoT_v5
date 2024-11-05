function [result_P,Total_benifit,exitflag_P,output_P, Accept_num, c_use_id, c_use_result, g_use_id, g_use_result, choosen_nodes, Accepted_Requests] = Solve_FP(...
    beta, P_matrix, V, c_now, g_now, Startfrom, Pointto, alpha, requests_K, cost_up, NoUp, HaveUpCost, idxs_d, Allow, K, c_use_id, g_use_id)
% 基于最短路径的Placement+Routing整体问题求解
% 用于PRB，无迭代的Baseline

% 求解PR整体问题
% 优化变量
L = requests_K.L;
M = size(Allow, 2);
E = size(P_matrix,2);
% Y(l,i,k) = 1, if 请求k中第l条link的起止点组合为情况i
Y = optimvar('Y', [L+1, V*V, K], 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
Y_1 = optimexpr(L+1, E, K);     % Y_1(l,e,k)
Y_d = optimexpr(L+1, V, K);
T = optimexpr(L+1, M, K);
for k = 1:K
    Y_1(:,:,k) = Y(:,:,k) * P_matrix;
    Y_d(:,:,k) = Y(:,:,k) * idxs_d;
    T(:,:,k) = Y_d(:,:,k) * Allow;
end
Y_d = Y_d(1:L, :, :);           % 取前L行，Y_d(l,v,k)=1 表示第k个请求链中第l个服务部署在节点v
T = T(1:L, :, :);               % 取前L行，T(l,m,k)=1 表示第k个请求链中第l个服务所在节点允许部署服务m


% X(v) = 1, if 本次请求有使用节点v
X = optimvar('X', [V, 1], 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

% A(k) = 1, if 请求k被接受
A = optimvar('A', [K, 1], 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);


%目标函数

% 1. 节点计算资源开销Cost_Node
% 按节点v求和
c_use = optimexpr(V,1);       % 创建空的优化表达式数组
% 计算c_use: 每个节点上的资源占用量
for k = 1:K
    cc = Y_d(:,:,k)' * requests_K.c_cost;  % V*1 vector
    c_use = c_use + cc;
end
if HaveUpCost == 1
    Cost_Node = alpha' * c_use + (cost_up .* NoUp)' * X;    % 考虑节点开机额外开销
else
    Cost_Node = alpha' * c_use;         % 不考虑开机额外开销
end

% 2. 估算链路总开销Cost_link
% 按链路e求和
g_use = optimexpr(E,1);
for k = 1:K
    gg = Y_1(:,:,k)' * requests_K.b_1;      % E*1 vector
    g_use = g_use + gg;
end
Cost_link = g_use' * beta;

Cost_Place = Cost_Node + Cost_link;

% Revenue = sum(A) * gamma;     % 对应固定的gamma
Revenue = A' * requests_K.gamma;           % 对应不固定的gamma

Placement = optimproblem('ObjectiveSense','max');
Placement.Objective = Revenue - Cost_Place;
% Placement.Objective = Revenue - Cost_link;

% 约束条件

% 1. 资源约束
% 1.1 节点资源约束
Placement.Constraints.cons1 = c_use <= c_now;       % V个约束
% 1.2 链路资源约束
Placement.Constraints.cons2 = g_use <= g_now;      % E个约束


% 2. 流守恒相关约束
% 2.1 起止点约束
sum_s = optimexpr(K,1);     % 注意，变成(K,1)，不再是(1,1)!!!
sum_d = optimexpr(K,1);
for k = 1:K
    start_node = requests_K.start_nodes(k);
    end_node = requests_K.end_nodes(k);
    for t = 1:size(Startfrom{start_node},1)
        i = Startfrom{start_node}(t);
        sum_s(k) = sum_s(k) + Y(1, i, k);
    end
    for t = 1:size(Pointto{end_node},1)
        i = Pointto{end_node}(t);
        sum_d(k) = sum_d(k) + Y(L+1, i, k);
    end
end
Placement.Constraints.cons3 = sum_s == A;       % 起点约束，K个
Placement.Constraints.cons4 = sum_d == A;       % 终点约束，K个


% 2.2 各段衔接约束
check_minus = optimexpr(V,L,K);       
for k = 1:K
    for l = 1:L
        for v = 1:V
            sum_1 = 0;
            for t = 1:size(Pointto{v},1)
                i = Pointto{v}(t);
                sum_1 = sum_1 + Y(l, i, k);
            end
            sum_2 = 0;
            for t = 1:size(Startfrom{v},1)
                i = Startfrom{v}(t);
                sum_2 = sum_2 + Y(l+1, i, k);
            end
            check_minus(v, l, k) = sum_1 - sum_2;
        end
    end
end
Placement.Constraints.cons5 = check_minus == 0;   % 共V*L*K个约束

% 3. 逻辑约束
% 3.1 对每个请求中的每个服务，仅指定一个节点
reshaped_sum = reshape(sum(Y, 2), [L+1, K]);
A_1 = repmat(A', L+1,1);         % L+1个1*K vector 按行堆叠，A_1为L+1*K matrix
Placement.Constraints.cons6 = reshaped_sum == A_1;            % 共K * L+1 个约束

% 3.2 开机逻辑约束
Placement.Constraints.cons7 = c_use ./ c_now <= X;      % V个约束

% 4. "节点-服务种类"匹配约束
Placement.Constraints.cons8 = optimconstr(K);
for k = 1:K
    Placement.Constraints.cons8(k) = trace( T(:,:,k) * (requests_K.F)' ) == L * A(k);   % 共K个约束
end


% 求解Placement问题
myoptions = optimoptions('intlinprog','Display','off');
% myoptions = optimoptions('intlinprog');
[result_P, Total_benifit, exitflag_P, output_P] = solve(Placement,'Options', myoptions);


% ==========================================================================================
% 求解完毕，统计结果
if exitflag_P == 1
    Accepted_Requests = result_P.A;
    Accept_num = sum(result_P.A);
    str = strcat('K = ',num2str(K),'条请求，接受其中',num2str(Accept_num),'条');
    disp(str);
    
    % 统计资源占用情况
    Y_1_result = zeros(L+1, E, K);
    Y_d_result = zeros(L+1, V, K);
    for k = 1:K
        Y_1_result(:,:,k) = result_P.Y(:,:,k) * P_matrix;
        Y_d_result(:,:,k) = result_P.Y(:,:,k) * idxs_d;
    end
    Y_d_result = Y_d_result(1:L, :, :);

%     g_use_result = zeros(E,1);
%     c_use_result = zeros(V,1);
%     start_id = requests_K.id(1);
    for k = 1:K
        gg_result = Y_1_result(:,:,k)' * requests_K.b_1;        % E*1 vector
        g_use_id(requests_K.id(k),:) = gg_result';                % 1*E
        cc_result = Y_d_result(:,:,k)' * requests_K.c_cost;     % V*1 vector
        c_use_id(requests_K.id(k),:) = cc_result';                % 1*V
    end
    g_use_result = sum( g_use_id(requests_K.id, :) );      % 求和，本次部署消耗的总资源量，1*E vector
    g_use_result = g_use_result';       % 转换为E*1 vector
    c_use_result = sum( c_use_id(requests_K.id, :) );      % 求和，本次部署消耗的总资源量，1*V vector
    c_use_result = c_use_result';       % 转换为V*1 vector

    % 统计每条请求选中的节点
    choosen_nodes = zeros(K,L);     % K*L matrix, 记录每条请求的L个服务所在节点号
    for k = 1:K
        if result_P.A(k) > 0.9
            Y_d_k = Y_d_result(:,:,k);
            for l = 1:L
                choosen_nodes(k,l) = find(Y_d_k(l,:)>0.1);
            end
        end
    end
    % 输出每条请求的部署结果
%     for k = 1:K
%         if result_P.A(k) > 0.9
%             str = strcat('第',num2str(k),'条请求中服务部署位置：');
%             disp(str);
%             disp(choosen_nodes(k,:));
%         else
%             str = strcat('第',num2str(k),'条请求被拒绝！：');
%             disp(str);
%         end
%     end

else
    disp('问题求解异常！');
    
    Accept_num = 0;
    g_use_id(requests_K.id,:) = zeros(K,E);
    g_use_result = zeros(E,1);
    c_use_id(requests_K.id,:) = zeros(K,V);
    c_use_result = zeros(V,1);
    choosen_nodes = zeros(K,L);
    Accepted_Requests = zeros(K,1);

end


end


