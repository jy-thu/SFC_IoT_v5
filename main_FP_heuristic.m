%%
% 2024.11.5创建
% 修改论文中请求接受率的图，变为曲线，(到目前为止的)接受率vs部署过程
% FP算法

clc; clear all; close all;

addpath(strcat(pwd, '\functions'));
load('Network_and_Request_Data_ws_4.mat');

rate = 0.75;

% plot(Graph_ini, 'EdgeLabel', g_ini);

HaveUpCost = 1;         % 是否考虑开机额外开销
beta = beta_ini;
alpha = alpha_ini;

K = 10;     % Batch Size


%%
TestNum = 100;                % 一共几次重复实验
for test_num = 1:TestNum     % 多次重复实验

    % 打乱请求起止点顺序
    [Req_start_nodes, Req_end_nodes] = ReGenReq(Region_Start, Region_End, rate, request_num, V);

    % 网络资源初始化
    c_now = c_ini;
    g_now = g_ini;
    
    % 初始化一些统计变量
    c_use_id = zeros(request_num, V);           % 每条请求的节点资源占用情况
    g_use_id = zeros(request_num, E);           % 每条请求的链路资源占用情况
    Success_Req = zeros(request_num,1);     % bool,记录每个请求是否被接受
    Alive_Req = zeros(request_num,1);       % bool,当前还有哪些请求活跃
    Benefit_Each_Batch = zeros(request_num/K, 1);   % 每批请求的收益
    Acccept_Rate_All = zeros(request_num/K, 1);       % 到目前位置的请求接受率
    % 最近一小段时间(tn个batch范围内，共tn*K条请求)的请求接受率
    tn = 1;
    Acccept_Rate_Recent = zeros(request_num/(K*tn), 1);
    
    Congest_Status = zeros(request_num/K, 3);        % 每行3个数：Num_idle, Num_mid, Num_Cong
    Theta_Status = zeros(request_num/K, E);          % 每行E个数：对应每批部署后E条链路上的带宽利用率theta(e)
    G_Use_Rate = zeros(request_num/K, 1);            % 网络总体带宽利用率
    Alive_num = zeros(request_num/K, 1);             % 每批部署结束后，网络中活跃请求总数

    % 分批部署所有请求
    for num_batch = 1 : request_num/K
    
        str = strcat('==========开始部署第',num2str(num_batch),'批请求==========');
        disp(str);
        [requests_K] = Get_Req_K(num_batch, K, Req_start_nodes, Req_end_nodes, Req_L, Req_F, Req_b, Req_b_1, c_cost_per, gamma);
        
        % 服务链部署问题求解，FixedPath算法
        [result_P,fval,exitflag_P,output_P, Accept_num, c_use_id, c_use_result, g_use_id, g_use_result, choosen_nodes, Accepted_Requests] = Solve_FP(...
                beta, P_matrix_ini, V, c_now, g_now, Startfrom, Pointto, alpha, requests_K, cost_up, NoUp, HaveUpCost, idxs_d, Allow, K, c_use_id, g_use_id);
        
        % 本批请求部署完，更新网络资源参数
        [c_now, g_now, NoUp] = Update_Net_State(c_now, g_now, NoUp, c_use_result, g_use_result, choosen_nodes);
    
        % 几个统计值
        Success_Req(requests_K.id) = Accepted_Requests;
        Alive_Req(requests_K.id) = Accepted_Requests;
        Alive_num(num_batch) = sum(Alive_Req);
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
%         [Num_idle, Num_mid, Num_Cong] = Get_Congest_Num(Graph_now.Edges.Weight);
%         Congest_Status(num_batch,:) = [Num_idle, Num_mid, Num_Cong];
        % 网络总体带宽资源利用率
        G_Use_Rate(num_batch) = 1-sum(g_now)/sum(g_ini);
    
    end
    
    % 保存本次实验结果
    base_num = 0;   % 之前已经有几个结果了，接着编号
    foldname = strcat(pwd, '\Save\1015\FP\');
    % foldname = strcat(pwd, '\Save\1016\FP\');
    filename = strcat('FP_', num2str(test_num+base_num));
    save(strcat(foldname, filename));


end


%%



%%



%%



