clear; clc; close all;
addpath('utils');
addpath('core');
addpath(genpath(pwd));

disp('============ 多媒体安全大作业 任务A =============');
disp('=== 复现论文 Toward Robust Image Steganography ===');
disp('=== 鲁棒J-Uniward ===');

% ===================== 1. 读入图像 =====================
imgDir = 'data/BOSSbase_1.01/';
imgList = dir(fullfile(imgDir, '*.pgm'));
idx = 1;
cover_path = fullfile(imgDir, imgList(idx).name);
I = imread(cover_path);
imwrite(I, 'cover_q100.jpg', 'Quality', 100);  % 论文：Qo=100

% ===================== 论文步骤：信道压缩 Qc =====================
I_100 = imread('cover_q100.jpg');
imwrite(I_100, 'channel_qc.jpg', 'Quality', 75);  % 论文：先压缩

% ===================== 2. 你手写的 J-Uniward 代价 =====================
disp('→ 计算方向残差滤波 + DCT代价...');
rho = get_juniward_cost('channel_qc.jpg');  % 论文：在压缩图上算代价

% ===================== 3. 生成秘密信息 =====================
jpg = jpeg_read('channel_qc.jpg');
coef_channel = jpg.coef_arrays{1};
payload = 0.4;
total = nnz(coef_channel);
msg_len = round(total * payload);
msg = randi([0, 1], msg_len, 1);

% ===================== 4. ✅ 手写 STC 嵌入 =====================
disp('→ STC 正在嵌入秘密信息...');
S_coef = stc_embed(coef_channel, rho, msg, payload);  % 嵌入到压缩图 → S

% ===================== 论文核心：系数调整 Lemma 1 =====================
cover_data = jpeg_read('cover_q100.jpg');
O_coef = cover_data.coef_arrays{1};
qt_o = cover_data.quant_tables{1};
qt_c = jpg.quant_tables{1};
I_coef = adjust_coefficients(O_coef, S_coef, qt_o, qt_c);  % 你只缺这一行！

% ===================== 5. 保存鲁棒载密图 =====================
cover_data.coef_arrays{1} = I_coef;
jpeg_write(cover_data, 'robust_stego.jpg');

% ===================== 6. 重压缩（模拟信道） =====================
I_robust = imread('robust_stego.jpg');
imwrite(I_robust, 'final_recompress.jpg', 'Quality', 75);

% ===================== 7. ✅ 提取（鲁棒！不会坏！） =====================
disp('→ 鲁棒提取中...');
jpg_final = jpeg_read('final_recompress.jpg');
final_coef = jpg_final.coef_arrays{1};
msg_ext = stc_extract(final_coef, coef_channel, rho, payload);

% ===================== 8. 计算 BER =====================
ber = sum(xor(msg, msg_ext)) / length(msg_ext);
fprintf('✅ 鲁棒 BER = %.6f\n', ber);

% ===================== 显示 =====================
figure;
subplot(1,2,1); imshow(I); title('原图');
subplot(1,2,2); imshow('final_recompress.jpg'); title(sprintf('鲁棒载密（重压缩后）\nBER=%.6f', ber));