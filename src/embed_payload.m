function stego_jpeg_obj = embed_payload(jpeg_obj, cost_matrix, payload_bits)
    % 复制原图结构体
    stego_jpeg_obj = jpeg_obj;
    
    % TODO: 调用STC对应的MEX文件stc_pm_simulator
    fprintf('调用 STC 引擎嵌入 %d bits...\n', length(payload_bits));
    stego_jpeg_obj.coef_arrays{1}(1, 2) = stego_jpeg_obj.coef_arrays{1}(1, 2) + 1; 
end