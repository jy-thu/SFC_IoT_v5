function [c_now, g_now, NoUp] = Update_Net_State(c_now, g_now, NoUp, c_use_result, g_use_result, choosen_nodes)
% 更新网络资源参数

c_now = c_now - c_use_result;
g_now = g_now - g_use_result;

[K, L] = size(choosen_nodes);
for k = 1:K
    for l = 1:L
        nn = choosen_nodes(k, l);
        if nn ~= 0
            NoUp(nn) = 0;        % 本次用到了节点n，标记为已开机
        end
    end
end

end

