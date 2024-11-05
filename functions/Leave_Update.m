function [c_now, g_now, Alive_Req] = Leave_Update(mu, c_now, g_now, Alive_Req, c_use_id, g_use_id)
%LEAVE_UPDATE 从当前活跃请求中随机选取mu个请求离去，更新网络资源

% 在Alive的请求中，随机选取mu个离去。
Alive_id = find(Alive_Req==1);
% 待加入：Alive_id数量<mu时的处理
Leave_idxs = randperm(size(Alive_id,1), mu);
Leave_id = Alive_id(Leave_idxs);
Alive_Req(Leave_id) = 0;

% free网络资源
c_free = sum( c_use_id(Leave_id, :) );      % 1*V vector
c_free = c_free';                           % V*1 vector
g_free = sum( g_use_id(Leave_id, :) );      % 1*E vector
g_free = g_free';                           % E*1 vector
c_now = c_now + c_free;
g_now = g_now + g_free;


end

