% 2024.10.18创建
% 设置网络参数和请求参数
% 120个节点的WS小世界网络

clc; clear all; close all;


% 1. 网络：
% 网络拓扑
V = 120;                              % 节点总数V
degree = 2;                              % 节点度（平均值）= 2*degree
E = V*degree;                            % 总边数 = V*K
Graph_ini = WattsStrogatz(V,degree,0.4);
graph_weights_ini = ones(E,1);
Graph_ini.Edges.Weights = graph_weights_ini;
plot(Graph_ini);


% 网络参数
NoUp = ones(V,1);                   % 初始所有节点均没有开机
cost_up = 0.3*ones(V,1);            % 节点开机的开销

idxs = Get_Idxs(V);                 % V*V * 2 matrix, 所有起止点组合情况
idxs_d = zeros(V*V, V);             % V*V * V matrix, =1, if 第i种组合的终点为v
for i = 1:V*V
    v = idxs(i,2);
    idxs_d(i,v) = 1;
end

% 过渡矩阵，描述每种起止点组合i的默认路由包括哪些链路e
P_matrix_ini = Get_P(idxs, Graph_ini, E);


% 映射：节点-->起止点组合号
Startfrom = {};
Pointto = {};
for v = 1:V
    Startfrom{v} = find(idxs(:,1)==v);
    Pointto{v} = find(idxs(:,2)==v);
end

% c_ini = 50 + 20*rand(V,1);                % 节点资源c，V*1 vector
c_ini = 30000 + 20*rand(V,1);                % 节点资源充足
alpha_ini = ones(V,1);                      % 每个节点v上，占用单位计算资源的价格

% g_ini = 1000 + randi([0,500], E,1);      % 链路带宽资源g，E*1 vector
g_ini = 1000 + randi([0,2000], E,1);      % 链路带宽资源g，E*1 vector
beta_ini = ones(E,1);                   % 每条链路上，单位带宽资源的价格

% 请求参数：
% 所有可用服务，共M种
M = 5;                              % 共有M种可用服务类型
c_cost_per = [0.01; 0.01; 0.01; 0.01; 1000];   % 每种类型的服务，处理单位负载消耗的计算资源, M*1 vector

Allow = ones(V,M);

% ===========================================================================================
%%
% 请求服务链参数
request_num = 200;          % 请求总数

% 起止点范围
Region_Start = [1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16];     % 服务链起点范围
Region_End = [105;106;107;108;109;110;111;112;113;114;115;116;117;118;119;120];      % 服务链终点范围
Req_start_nodes = ones(request_num,1);
Req_end_nodes = ones(request_num,1);

start_idx = randi(size(Region_Start,1), request_num,1);
end_idx = randi(size(Region_End,1), request_num,1);
for nn = 1:request_num
    Req_start_nodes(nn) = Region_Start(start_idx(nn));
    Req_end_nodes(nn) = Region_End(end_idx(nn));
end

% 成功部署的收益
gamma = zeros(request_num,1);
for nn = 1:request_num
    [~, Req_Dist(nn), ~] = shortestpath( Graph_ini, Req_start_nodes(nn), Req_end_nodes(nn) );
    gamma(nn) = 400 + 100 * Req_Dist(nn);
end

% 服务链长度、服务种类顺序，暂且固定，所有请求都相同
Req_L = 2;
Req_F = [1,0,0,0,0;         % 服务链描述矩阵，L*M
        0,1,0,0,0];
Req_b = [100;100];          % 第l个服的输入data rate(服务负载), L*1 vector
Req_B = diag(Req_b);
Req_b_1 = [Req_b;100];                  % 链路负载，共L+1条link的带宽需求
Req_B_1 = diag(Req_b_1);
Req_c_cost = (Req_F*c_cost_per) .* Req_b;       % 第l个服务的计算资源消耗量，L*1 vector


%%

% 保存工作区到mat文件
Data_filename = strcat('Net_ws_',num2str(V),'.mat');
save(Data_filename);

%%


