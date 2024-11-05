function [Req_start_nodes,Req_end_nodes] = ReGenReq(Region_Start, Region_End, rate, request_num, V)
% 给定服务请求分布参数，生成一组服务请求起止点
Req_start_nodes = ones(request_num,1);
Req_end_nodes = ones(request_num,1);
start_idx = randi(size(Region_Start,1), request_num*rate,1);
end_idx = randi(size(Region_Start,1), request_num*rate,1);
% 生成占rate比例的、落在起止点区域内的请求
for nn = 1:request_num*rate
    Req_start_nodes(nn) = Region_Start(start_idx(nn));
    Req_end_nodes(nn) = Region_End(end_idx(nn));
end
% 剩余请求起止点随机
Req_start_nodes(request_num*rate +1 : request_num) = randi(V, request_num*(1-rate),1);
Req_end_nodes(request_num*rate +1 : request_num) = randi(V, request_num*(1-rate),1);
% 打乱顺序
Req_start_end = [Req_start_nodes, Req_end_nodes];
rowrank = randperm(size(Req_start_end,1));
Req_start_end = Req_start_end(rowrank,:);
Req_start_nodes = Req_start_end(:,1);
Req_end_nodes = Req_start_end(:,2);

end

