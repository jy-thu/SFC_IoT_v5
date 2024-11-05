function [Total_benifit, c_use_id, c_use_result, g_use_id, g_use_result, choosen_nodes, Accepted_Requests] = Solve_Heuristic(...
    beta, P_matrix, V, c_now, g_now, alpha, requests_K, Allow, K, c_use_id, g_use_id)
% 简单的启发式算法，用于对照

% Output:
% Benefit：本批部署净收益(优化目标)
% c_use_id：每条请求(id=1~200)的节点资源占用情况，200*V
% c_use_result：本批部署在每个节点上消耗的总资源量，1*V
% g_use_id：每条请求(id=1~200)的链路资源占用情况，200*E
% g_use_result：本批部署在每条链路上消耗的总资源量，1*E
% choosen_nodes：记录每条请求的L个服务所在节点号，K*L
% Accepted_Requests：记录本批每个请求的接受情况(0/1)，K*1

L = requests_K.L;
M = size(Allow, 2);
E = size(P_matrix,2);

% 优化变量

% A(k) = 1, if 请求k被接受
A = optimvar('A', [K, 1], 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
% Y_d(l,v,k)=1, if 请求k第l个服务被部署在节点v
Y_d = optimvar('Y_d', [L, V, K], 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
% T(l,m,k)=1, if 第k个请求链中第l个服务所在节点允许部署服务m
T = optimexpr(L, M, K);
for k = 1:K
    T(:,:,k) = Y_d(:,:,k) * Allow;
end


%目标函数

% 1. 节点计算资源开销Cost_Node
% 按节点v求和
c_use = optimexpr(V,1);       % 创建空的优化表达式数组
% 计算c_use: 每个节点上的资源占用量
for k = 1:K
    cc = Y_d(:,:,k)' * requests_K.c_cost;  % V*1 vector
    c_use = c_use + cc;
end
% c_use = zeros(V,1);               % ?????暂定c_use全是0?????
Cost_node = alpha' * c_use;         % 不考虑开机额外开销

% 2. 估算链路总开销Cost_link
% 按链路e求和
g_use = optimexpr(E,1);
% 根据最短路径，计算g_use





% ！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！






Cost_link = g_use' * beta;

Revenue = A' * requests_K.gamma;           % 不固定的gamma

Routing = optimproblem('ObjectiveSense','max');
Routing.Objective = Revenue - (Cost_link + Cost_node);

% 约束条件
% 1. 资源约束
% 1.1 节点资源约束
Placement.Constraints.node_cons = c_use <= c_now;       % V个约束
% 1.2 链路资源约束
Placement.Constraints.link_cons = g_use <= g_now;       % E个约束

% 2. 流守恒相关约束
% 2.1 起止点约束（此算法无）
% 2.2 各段衔接约束（此算法无）
% 2.3 先routing后placement，要求选中的部署节点在shortest path上





% ！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！





% 3. "节点-服务种类"匹配约束
Placement.Constraints.SLA_cons = optimconstr(K);
for k = 1:K
    Placement.Constraints.SLA_cons(k) = trace( T(:,:,k) * (requests_K.F)' ) == L * A(k);   % 共K个约束
end

% 4. 逻辑约束
% 对每个请求k中的每个服务l，仅指定一个节点
reshaped_sum = reshape(sum(Y_d, 2), [L, K]);
A_1 = repmat(A', L, 1);                                     % L个1*K vector 按行堆叠，A_1为L*K matrix
Routing.Constraints.logic_cons = reshaped_sum == A_1;       % 共K*L个约束


% 求解优化问题
myoptions = optimoptions('intlinprog','Display','off');
[result_R, Total_benifit, exitflag_R, ~] = solve(Routing,'Options', myoptions);

% ==========================================================================================
% 求解完毕，统计结果
if exitflag_R == 1
    Accepted_Requests = result_R.A;
    Accept_num = sum(result_R.A);
    str = strcat('K = ',num2str(K),'条请求，接受其中',num2str(Accept_num),'条');
    disp(str);
    % 统计资源占用情况
    Y_d_result = result_R.Y_d;
    for k = 1:K
        cc_result = Y_d_result(:,:,k)' * requests_K.c_cost;         % V*1 vector
        c_use_id(requests_K.id(k),:) = cc_result';                  % 1*V

    end






% ！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！






else
    disp('问题求解异常！');
    % Accept_num = 0;
    g_use_id(requests_K.id,:) = zeros(K,E);
    g_use_result = zeros(E,1);
    c_use_id(requests_K.id,:) = zeros(K,V);
    c_use_result = zeros(V,1);
    choosen_nodes = zeros(K,L);
    Accepted_Requests = zeros(K,1);
end





end

