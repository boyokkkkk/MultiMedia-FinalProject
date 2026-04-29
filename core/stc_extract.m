function msg_ext = stc_extract(wechat_coef, simulated_cover_coef, cost_map, payload)
    % QIM 盲提取法
    [h, w] = size(wechat_coef);
    idx_list = [];
    cost_list = [];
    
    for i = 1:h
        for j = 1:w
            if simulated_cover_coef(i,j) ~= 0
                idx_list = [idx_list; i, j];
                cost_list = [cost_list; cost_map(i,j)];
            end
        end
    end
    
    [~, sorted_idx] = sort(cost_list);
    msg_len = round(size(idx_list,1) * payload);
    msg_ext = zeros(msg_len, 1);
    
    step = 3;
    
    for k = 1:msg_len
        i = idx_list(sorted_idx(k), 1);
        j = idx_list(sorted_idx(k), 2);
        
        % QIM 提取逻辑：吸收 +-1 误差后判决
        msg_ext(k) = mod(round(abs(wechat_coef(i,j)) / step), 2);
    end
end