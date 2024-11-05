function [weights] = weight_func(theta)
% 链路权重与利用率的关系
% 分段函数

K = size(theta,1);      % 链路资源利用率，E*1 vector
weights = ones(K,1);

for kk = 1:K
    if theta(kk) < 0.5
        weights(kk) = 1;
    elseif theta(kk) < 0.8
        weights(kk) = 1.1;
    else
        weights(kk) = 2.1;

    end
    
end
end

