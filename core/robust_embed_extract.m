function ber = robust_embed_extract(cover_Qo_jpg, channel_Qc_jpg, rho, payload, Qo, Qc)
    % ==========================
    % 纯DCT系数运算 · 无图 · 无误差 · 无尺寸报错
    % ==========================

    % 1. 读取信道压缩图的系数和量化表
    jpg_c = jpeg_read(channel_Qc_jpg);
    C = jpg_c.coef_arrays{1};
    qt_c = jpg_c.quant_tables{1};

    % 2. 读取原始Qo图的系数和量化表
    jpg_o = jpeg_read(cover_Qo_jpg);
    O = jpg_o.coef_arrays{1};
    qt_o = jpg_o.quant_tables{1};

    % 3. 生成消息
    nbits = round(nnz(C) * payload);
    msg = randi([0 1], nbits, 1);

    % 4. 嵌入得到目标系数 S
    S = stc_embed(C, rho, msg, payload);

    % 5. 系数调整（你的函数，完全不变）
    I_coef = adjust_coefficients(O, S, qt_o, qt_c);

    % ==========================
    % 关键修复：正确压缩（无图、无误差、不存图）
    % ==========================
    S_re = zeros(size(I_coef)); % 和系数一样大
    [h, w] = size(I_coef);

    % 逐8×8块使用量化表（论文标准！不会尺寸不兼容！）
    for i = 1:8:h
        for j = 1:8:w
            block = I_coef(i:i+7, j:j+7);
            % 论文核心公式：压缩 = I_coef .* (Qo / Qc) 然后取整
            block_re = round( block .* (qt_o ./ qt_c) );
            S_re(i:i+7, j:j+7) = block_re;
        end
    end

    % 6. 提取信息
    msg_ext = stc_extract(S_re, C, rho, payload);

    % 7. 计算BER
    ber = sum(xor(msg, msg_ext)) / length(msg_ext);
end