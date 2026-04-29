function stego_coef = stc_embed(cover_coef, cost_map, msg, payload)
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

    for k = 1:num_embed
        i = idx_list(sorted_idx(k), 1);
        j = idx_list(sorted_idx(k), 2);
        if msg(k) == 1
            stego_coef(i,j) = stego_coef(i,j) + 1;
        end
    end
end