function ber = embed_extract(cover_Qo_jpg, rho, payload, Qc)

    % 1. 读 Qo 载体
    jpg = jpeg_read(cover_Qo_jpg);
    cover_coef = jpg.coef_arrays{1};

    % 2. 生成消息
    nbits = round(nnz(cover_coef) * payload);
    msg = randi([0 1], nbits, 1);

    % 3. 在 Qo 上嵌入
    stego_coef = stc_embed(cover_coef, rho, msg, payload);

    % 4. 保存载密图
    jpg.coef_arrays{1} = stego_coef;
    jpeg_write(jpg, 'result/stego_Qo.jpg');

    % 5. 模拟传输：信道压缩 Qc
    Istego = imread('result/stego_Qo.jpg');
    imwrite(Istego, 'result/transmitted_Qc.jpg', 'Quality', Qc);

    % 6. 读取压缩后的系数并提取
    jpg_recv = jpeg_read('result/transmitted_Qc.jpg');
    recv_coef = jpg_recv.coef_arrays{1};

    % 7. 提取
    msg_ext = stc_extract(recv_coef, cover_coef, rho, payload);

    % 8. BER
    ber = sum(xor(msg, msg_ext)) / length(msg_ext);
end