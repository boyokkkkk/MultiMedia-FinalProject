function feat = feature_spam(img)
    % 简化版 SPAM 特征（StegExpose 核心逻辑）
    % 输入：灰度图
    % 输出：特征向量 (用来区分 载体/载密)
    img = double(img);
    [h, w] = size(img);
    
    % 定义 8x8 网格
    block_size = 8;
    gh = floor(h/block_size)*block_size;
    gw = floor(w/block_size)*block_size;
    img = img(1:gh, 1:gw);
    
    feat = [];
    for i = 1:block_size:gh
        for j = 1:block_size:gw
            block = img(i:i+block_size-1, j:j+block_size-1);
            % 计算一阶/二阶统计量（模拟 SPAM 特征）
            bc = sum(block(:));
            bc2 = sum(block(:).^2);
            feat = [feat, bc, bc2];
        end
    end
    feat = feat / norm(feat);
end