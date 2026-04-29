function msg_ext = stc_extract(stego_coef, cover_coef, cost_map, payload)
    [h, w] = size(stego_coef);
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
    msg_len = round(size(idx_list,1) * payload);
    msg_ext = zeros(msg_len,1);

    for k = 1:msg_len
        i = idx_list(sorted_idx(k),1);
        j = idx_list(sorted_idx(k),2);
        if stego_coef(i,j) ~= cover_coef(i,j)
            msg_ext(k) = 1;
        end
    end
end