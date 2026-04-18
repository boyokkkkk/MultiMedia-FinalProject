function cost_matrix = get_juniward_cost(jpeg_obj)
    % 获取DCT矩阵尺寸
    dct_matrix = jpeg_obj.coef_arrays{1};
    [rows, cols] = size(dct_matrix);

    % TODO:实现J-Uniward
    cost_matrix = ones(rows, cols);

    cost_matrix(1:8:end, 1:8:end) = 1e5;
    cost_matrix(dct_matrix == 0) = 1e5;

    fprintf('J-Uniward基础Cost矩阵计算完成.\n');
end