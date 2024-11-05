function [Num_idle, Num_mid, Num_Cong] = Get_Congest_Num(weight_now)
% Get_Congest_Num

% weight_now = Graph_now.Edges.Weight;    % E*1 vector
% E = size(wt,1);

Num_idle = size(find(weight_now==1), 1);
Num_mid = size(find(weight_now==1.1), 1);
Num_Cong = size(find(weight_now==2.1), 1);

% 或者使用tabulate函数：tt = tabulate(Graph_now.Edges.Weight);


end

