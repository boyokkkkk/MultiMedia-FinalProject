clear; clc; close all;

addpath(genpath(pwd));

test_dir = './data/BOSSbase_qf75';
files = dir(fullfile(test_dir, '*.jpg'));

if isempty(files)
    error('未在%s找到jpg图像,请先运行pipeline/prepare_datasets.m脚本!\n', test_dir);
end

test_num = min(10, length(files));
fprintf('>>> 开始批量IO测试, 测试数量: %d张\n', test_num);
io_start = tic;
for i = 1: test_num
    img_path = fullfile(test_dir, files(i).name);
    C_STRUCT = jpeg_read(img_path);
    % 提取DCT矩阵
    dct_matrix = C_STRUCT.coef_arrays{1};

    [h, w] = size(dct_matrix);
    if h ~= 512 || w ~= 512
        warning('图像%s尺寸异常: %dx%d', files(i).name, h, w);
    end

    C_STRUCT.coef_arrays{1}(1, 1) = C_STRUCT.coef_arrays{1}(1, 1) + 1;
    temp_out_path = fullfile(test_dir, ['temp_io_test_', files(i).name]);
    jpeg_write(C_STRUCT, temp_out_path);
    delete(temp_out_path);
end
io_end = toc(io_start);

fprintf('>>> 批量 I/O 测试通过！\n');
fprintf('平均每张图的 [读取+修改+重写] 耗时: %.4f 秒\n', io_end / test_num);
disp('底层DCT提取管道已经跑通，可以对接J-Uniward引擎了.');