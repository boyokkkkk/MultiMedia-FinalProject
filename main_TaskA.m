clear; clc; close all;
addpath(genpath(pwd));

disp('多媒体安全大作业: 任务A');

cover_path = fullfile('data_test', '1.jpg');
stego_path = fullfile('data_test', 'stego_1.jpg');

if ~exist(cover_path, 'file')
    error('错误: 未在%s找到载体图像，请确认文件已放入data目录！', cover_path);
end

temp_img = imread(cover_path);
if size(temp_img, 3) == 3
    fprintf('检测到彩色图像，正在自动转换为单通道灰度图...\n');
    temp_img = rgb2gray(temp_img);
    gray_cover_path = fullfile('data_test', '1_gray.jpg');
    imwrite(temp_img, gray_cover_path, 'Quality', 85); 
    cover_path = gray_cover_path; 
end

% 嵌入参数
payload = single(0.2);
config.STC_h = uint32(0);
config.seed = int32(123);
fprintf('--- 启动J-Uniward嵌入 ---\n');
MEXstart = tic;

distortion = J_UNIWARD(cover_path, stego_path, payload, config);
MEXend = toc(MEXstart);
fprintf('嵌入完成 耗时 %.4fs 失真度 %.4f\n', MEXend, distortion);

try
    C_STRUCT = jpeg_read(cover_path);
    S_STRUCT = jpeg_read(stego_path);

    nzAC = nnz(C_STRUCT.coef_arrays{1}) - nnz(C_STRUCT.coef_arrays{1}(1:8:end, 1:8:end));
    diff_count = sum(S_STRUCT.coef_arrays{1}(:) ~= C_STRUCT.coef_arrays{1}(:));
    change_rate = diff_count / nzAC;

    fprintf('--- 实验统计数据 ---\n');
    fprintf('非零AC系数总数: %d\n', nzAC);
    fprintf('发生修改的系数个数: %d\n', diff_count);
    fprintf('实际修改率: %.4f (每 nzAC)\n', change_rate);

    C_SPATIAL = imread(cover_path);
    S_SPATIAL = imread(stego_path);
    
    figure('Name', 'J-Uniward 嵌入结果对比');
    subplot(1,2,1); imshow(C_SPATIAL); title('原始载体图 (Cover)');
    subplot(1,2,2); imshow(S_SPATIAL); title('载密图 (Stego)');
catch ME
    fprintf('\n读取结果失败，请确保 utils/ 文件夹下已有编译好的 jpeg_read.mexw64\n');
    rethrow(ME);
end