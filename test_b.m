clear; clc; close all;
addpath('utils');
addpath('core');
addpath(genpath(pwd));

disp('============ 多媒体安全大作业 任务A =============');
disp('=== 普通J-Uniward隐写 + STC嵌入 + 信息隐藏 ===');

% ===================== 1. 读入图像 =====================
imgDir = 'data/BOSSbase_1.01/';
imgList = dir(fullfile(imgDir, '*.pgm'));
idx = 1;
cover_path = fullfile(imgDir, imgList(idx).name);
I = imread(cover_path);
imwrite(I, 'cover.jpg', 'Quality', 85);

% ===================== 2. 你手写的 J-Uniward 代价 =====================
disp('→ 计算方向残差滤波 + DCT代价...');
rho = get_juniward_cost('cover.jpg');

% ===================== 3. 生成秘密信息 =====================
jpg = jpeg_read('cover.jpg');
coef = jpg.coef_arrays{1};
payload = 0.4;
total = nnz(coef);
msg_len = round(total * payload);
msg = randi([0, 1], msg_len, 1);

% ===================== 4. ✅ 手写 STC 嵌入 =====================
disp('→ STC 正在嵌入秘密信息...');
stego_coef = stc_embed(coef, rho, msg, payload);

% ===================== 5. 保存载密图 =====================
jpg.coef_arrays{1} = stego_coef;
jpeg_write(jpg, 'stego.jpg');

% ===================== 6. ✅ 手写 STC 提取 =====================
disp('→ STC 正在提取...');
msg_ext = stc_extract(stego_coef, coef, rho, payload);

% ===================== 7. 计算 BER =====================
ber = sum(xor(msg(1:length(msg_ext)), msg_ext)) / length(msg_ext);

% ===================== 8. 显示结果 =====================
figure('Position',[100,100,900,300]);
subplot(1,3,1); imshow(I); title('载体图像');
subplot(1,3,2); imagesc(rho); colormap jet; colorbar; title('J-Uniward 代价');
subplot(1,3,3); imshow(imread('stego.jpg')); title('载密图像');
sgtitle(sprintf('嵌入率 %.2f | BER = %.6f', payload, ber));

fprintf('==================================================\n');
fprintf('✅ 完全手写 J-Uniward + STC 完成！\n');
fprintf('✅ 不需要任何 stc_embed.mexw64\n');
fprintf('==================================================\n');

% ===================== 9. 隐写分析结果对比 =====================
disp('→ 运行传统隐写分析 StegExpose (SPAM特征)...');

% 读取两张图
cover_img = imread('cover.jpg');
stego_img = imread('stego.jpg');

% 提取特征
feat_cover = feature_spam(cover_img);
feat_stego = feature_spam(stego_img);

% 计算特征相似度 (距离越近，越难被检测)
distance = sum((feat_cover - feat_stego).^2);

fprintf('==================================================\n');
fprintf('📊 隐写分析结果 (StegExpose 简化版) \n');
fprintf('🔑 载体 vs 载密 特征距离：%.6f\n', distance);
if distance < 0.01
    fprintf('📌 结论：算法隐蔽性良好，传统检测较难发现！\n');
else
    fprintf('📌 结论：算法隐蔽性一般，检测较容易！\n');
end
fprintf('==================================================\n');