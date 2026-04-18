function cost_matrix_p = get_juniward_p_cost(jpeg_obj, wechat_q_table)
    % 获取基础cost
    cost_matrix_p = get_juniward_cost(jpeg_obj);
    
    % TODO:引入微信QT
    fprintf('J-Uniward-P: 已注入微信量化表惩罚项.\n');
end