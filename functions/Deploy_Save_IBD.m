function Deploy_Save_IBD(reqfile, outfile)
% 内容同main_IBD_01，使用IBD算法部署Req_file中的所有请求，保存结果于outfile

% addpath('C:\matlab_files_jy\SFC_BBO_v2\functions');
load(reqfile);    % 0928_01.mat：1600条请求，4种分布，每种400条
max_iter = 3;       % 内部迭代最多次数，置为1时变为SIBD

HaveUpCost = 1;         % 是否考虑开机额外开销
beta = beta_ini;
alpha = alpha_ini;

K = 10;     % Batch Size

% 网络资源初始化
c_now = c_ini;
g_now = g_ini;
% 初始情况，P矩阵为初始值
Graph_now = Graph_ini;
P_now = P_matrix_ini;
P_matrix_new = P_matrix_ini;
prob = 0.5 * ones(V^2, 1);

% 初始化一些统计变量
c_use_id = zeros(request_num, V);           % 每条请求的节点资源占用情况
g_use_id = zeros(request_num, E);           % 每条请求的链路资源占用情况

Success_Req = zeros(request_num,1);     % bool,记录每个请求是否被接受
Alive_Req = zeros(request_num,1);       % bool,当前还有哪些请求活跃
Benefit_Each_Batch = zeros(request_num/K, 1);   % 每批请求的收益
Acccept_Rate_All = zeros(request_num/K, 1);       % 到目前位置的请求接受率
% 最近一小段时间(tn个batch范围内，共tn*K条请求)的请求接受率
tn = 4;
Acccept_Rate_Recent = zeros(request_num/(K*tn), 1);

Congest_Status = zeros(request_num/K, 3);        % 每行3个数：Num_idle, Num_mid, Num_Cong
Theta_Status = zeros(request_num/K, E);          % 每行E个数：对应每批部署后E条链路上的带宽利用率theta(e)
G_Use_Rate = zeros(request_num/K, 1);            % 网络总体带宽利用率

% 外部迭代，依次部署每批请求
for num_batch = 1 : request_num/K
    
    % 在部署每批请求之前，看有哪些请求离去，更新网络资源
    if num_batch >= 21
        mu = 6;
        [c_now, g_now, Alive_Req] = Leave_Update(mu, c_now, g_now, Alive_Req, c_use_id, g_use_id);
    end

    % 检查是否需要进行资源预分配
    % if (多种触发条件), (c,g) = BBO()

    str = strcat('==========开始部署第',num2str(num_batch),'批请求==========');
    disp(str);
    [requests_K] = Get_Req_K(num_batch, K, Req_start_nodes, Req_end_nodes, Req_L, Req_F, Req_b, Req_b_1, c_cost_per, gamma);
    
    % P_now初始化，和上一个batch的P_new相同
    P_now = P_matrix_new;
    
    % 每批请求部署内部迭代
    num_iterat = 1;
    while 1
        weights_0 = Graph_now.Edges.Weight;     % 记下本轮迭代开始前的边权重
        
        % 求解优化问题
        [result_P,fval,exitflag_P,output_P, Accept_num, c_use_id, c_use_result, g_use_id, g_use_result, choosen_nodes, Accepted_Requests] = Solve_IBD(...
        beta, P_now, P_matrix_new, prob, V, c_now, g_now, Startfrom, Pointto, alpha, requests_K, cost_up, NoUp, HaveUpCost, idxs_d, Allow, K, c_use_id, g_use_id);

        % 评估本轮迭代，更新路由矩阵P
        [Graph_now, P_matrix_new, prob] = Update_Graph_P_2(g_use_result, g_ini, g_now, idxs, P_matrix_ini, Graph_now);
        weights_now = Graph_now.Edges.Weight;
    
        % 判断迭代停止条件
        if sum(weights_now) <= sum(weights_0)   % 网络平均拥塞度不增长
            break;
        end
        if num_iterat >= max_iter      % 最多迭代几次
            break;
        end
    
        num_iterat = num_iterat + 1;

    end

    % 本批请求部署完，更新网络资源参数
    [c_now, g_now, NoUp] = Update_Net_State(c_now, g_now, NoUp, c_use_result, g_use_result, choosen_nodes);

    % 几个统计值
    Success_Req(requests_K.id) = Accepted_Requests;
    Alive_Req(requests_K.id) = Accepted_Requests;
    Benefit_Each_Batch(num_batch) = fval;
    Acccept_Rate_All(num_batch) = sum(Success_Req) / (num_batch*K);
    if mod(num_batch, tn) == 0
        RecentRange = num_batch*K - tn*K + 1 : num_batch*K;
        Acccept_Rate_Recent(num_batch/tn) = sum(Success_Req(RecentRange)) / (K*tn);
    end
    % 各链路的带宽利用率
    tt_now = (ones(E,1) - g_now ./ g_ini)';     % 1*E vector
    Theta_Status(num_batch,:) = tt_now;
    % 三种拥塞程度链路的数量
    [Num_idle, Num_mid, Num_Cong] = Get_Congest_Num(Graph_now.Edges.Weight);
    Congest_Status(num_batch,:) = [Num_idle, Num_mid, Num_Cong];
    % 网络总体带宽资源利用率
    G_Use_Rate(num_batch) = 1-sum(g_now)/sum(g_ini);

end

% 保存本次实验结果
save(outfile);

end

