function ber = robust_embed_extract(cover_Qo_jpg, channel_Qc_jpg, rho, payload, Qo, Qc)
    % 1. 读取信道图系数
    jpg_c = jpeg_read(channel_Qc_jpg);
    coef_c = jpg_c.coef_arrays{1};
    
    % 2. 生成消息
    nbits = round(nnz(coef_c) * payload);
    msg = randi([0 1], nbits, 1);
    
    % 3. 嵌入得到 S
    S_coef = stc_embed(coef_c, rho, msg, payload);
    
    % 4. 系数调整
    jpg_o = jpeg_read(cover_Qo_jpg);
    O_coef = jpg_o.coef_arrays{1};
    qt_o = jpg_o.quant_tables{1};
    qt_c = jpg_c.quant_tables{1};
    I_coef = adjust_coefficients(O_coef, S_coef, qt_o, qt_c);
    
    % 5. 保存中间图
    jpg_o.coef_arrays{1} = I_coef;
    jpeg_write(jpg_o, 'result/intermediate.jpg');
    
    % 6. 信道重压缩
    qt_o_full = jpg_o.quant_tables{1};
    qt_c_full = jpg_c.quant_tables{1};
    final_coef = zeros(size(I_coef));
    for i=1:size(I_coef,1)
        for j=1:size(I_coef,2)
            mo = qt_o_full(mod(i-1,8)+1, mod(j-1,8)+1);
            mc = qt_c_full(mod(i-1,8)+1, mod(j-1,8)+1);
            final_coef(i,j)=round(I_coef(i,j)*mo/mc);
        end
    end
    msg_ext = stc_extract(final_coef, coef_c, rho, payload);
    
    L = min(length(msg), length(msg_ext));
    ber = sum(xor(msg(1:L), msg_ext(1:L))) / L;
end