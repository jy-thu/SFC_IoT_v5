function [requests_K] = Get_Req_K(n, K, Req_start_nodes, Req_end_nodes, Req_L, Req_F, Req_b, Req_b_1, c_cost_per, gamma)
% 读取第n批K个请求
requests_K.id = (n-1)*K+1 : n*K;        % 本次部署请求的id范围
requests_K.start_nodes = Req_start_nodes((n-1)*K+1 : n*K );
requests_K.end_nodes = Req_end_nodes((n-1)*K+1 : n*K);
requests_K.gamma = gamma((n-1)*K+1 : n*K);

requests_K.L = Req_L;
requests_K.F = Req_F;
requests_K.b = Req_b;
requests_K.B = diag(Req_b);
requests_K.b_1 = Req_b_1;
requests_K.B_1 = diag(Req_b_1);
requests_K.c_cost = (Req_F*c_cost_per) .* Req_b;

end

