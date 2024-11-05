function [idxs] = Get_Idxs(V)
% 共V*V种起止点组合，存于idxs中，V*V * 2 matrix
idxs = [];
for s = 1:V
    for d = 1:V
        tt = [s,d];
        idxs = [idxs; tt];
    end
end
end

