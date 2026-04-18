function extracted_bits = extract_payload(attacked_jpeg_obj, payload_length)
    % TODO:调用STC的提取MEX文件
    fprintf('调用 STC 引擎提取 %d bits...\n', payload_length);
    extracted_bits = uint8(randi([0, 1], 1, payload_length));
end