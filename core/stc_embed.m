function stego_coef = stc_embed(cover_coef, cost_map, msg, payload)
    % QIM (Quantization Index Modulation) 鲁棒嵌入算法
    stego_coef = cover_coef;
    [h, w] = size(cover_coef);
    idx_list = [];
    cost_list = [];
    
    for i = 1:h
        for j = 1:w
            if cover_coef(i,j) ~= 0
                idx_list = [idx_list; i, j];
                cost_list = [cost_list; cost_map(i,j)];
            end
        end
    end
    
    [~, sorted_idx] = sort(cost_list);
    num_embed = length(msg);
    
    % 核心：设置 QIM 容错步长为 3 (可抵抗 +-1 的漂移)
    step = 3; 
    
    for k = 1:num_embed
        i = idx_list(sorted_idx(k), 1);
        j = idx_list(sorted_idx(k), 2);
        
        current_coef = stego_coef(i,j);
        target_bit = msg(k);
        
        % 计算当前系数距离哪个锚点最近
        K_float = current_coef / step;
        K_round = round(K_float);
        
        if mod(abs(K_round), 2) == target_bit
            % 最近的锚点正好符合目标 bit
            best_X = K_round * step;
        else
            % 最近的锚点不符合，向第二近的锚点偏移
            if K_float > K_round
                K_new = K_round + 1;
            else
                K_new = K_round - 1;
            end
            best_X = K_new * step;
        end
        
        % 绝对护栏：防止原本非0的系数变成0，破坏同步索引
        if best_X == 0
             if current_coef > 0
                 best_X = step * 2; % 映射到最近的 0 锚点 (6)
             else
                 best_X = -step * 2; % 映射到最近的 0 锚点 (-6)
             end
        end
        
        stego_coef(i,j) = best_X;
    end
end