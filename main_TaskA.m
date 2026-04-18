clear; clc; close all;

disp('多媒体安全大作业: 任务A');
cover_obj.image_width = 256;
cover_obj.image_height = 256;
cover_obj.coef_arrays{1} = int16(randi([-10, 10], 256, 256));
cover_obj.quant_tables{1} = ones(8, 8) * 10;

alpha = 0.1;
payload_length = 1000; % 假设要藏1000个bits
original_bits = uint8(randi([0, 1], 1, payload_length));

cost = get_juniward_cost(cover_obj);

stego_obj = embed_payload(cover_obj, cost, original_bits);

received_obj = stego_obj;

extracted_bits = extract_payload(received_obj, payload_length);

ber = calculate_ber(original_bits, extracted_bits);
fprintf('\n--- 最终报告 ---\n');
fprintf('嵌入率: %.1f\n', alpha);
fprintf('误码率: %.4f\n', ber);