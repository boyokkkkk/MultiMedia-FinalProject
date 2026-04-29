clear; clc; close all;

addpath(genpath(pwd));

qf_folder = 'qf752_0.1'; % 每次根据具体测试填写
origin_dir = fullfile('./data/wechat_test_covers', qf_folder);
wechat_dir = fullfile('./data/wechat_downloaded', qf_folder);

origin_files = dir(fullfile(origin_dir, '*.jpg'));
num_files = length(origin_files);
if num_files == 0
    error('在%s中找不到原始测试图片！请确认路径', origin_dir);
end

fprintf('>>> 找到%d张测试图片，开始批量分析...\n', num_files);

all_wechat_qts = zeros(8, 8, num_files);
is_qt_consistent = true;
valid_count = 0;

for i = 1: num_files
    origin_name = origin_files(i).name;
    origin_path = fullfile(origin_dir, origin_name);
    [~, name_base, ext] = fileparts(origin_name);

    wechat_path_1 = fullfile(wechat_dir, [name_base, '_stego', ext]);
    wechat_path_2 = fullfile(wechat_dir, origin_name);

    if exist(wechat_path_1, 'file')
        wechat_path = wechat_path_1;
    elseif exist(wechat_path_2, 'file')
        wechat_path = wechat_path_2;
    else
        fprintf('找不到%s对应的微信下载图，跳过.\n', origin_name);
        continue;
    end

    origin_struct = jpeg_read(origin_path);
    wechat_struct = jpeg_read(wechat_path);

    if origin_struct.image_width ~= wechat_struct.image_width || origin_struct.image_height ~= wechat_struct.image_height
        fprintf('图片%s发生尺寸缩放(%dx%d -> %dx%d)\n', ...
            origin_name, origin_struct.image_width, origin_struct.image_height, ...
            wechat_struct.image_width, wechat_struct.image_height);
    else
        fprintf('图片%s 尺寸一致。\n', origin_name);
    end

    origin_qt = origin_struct.quant_tables{1};
    wechat_qt = wechat_struct.quant_tables{1};

    valid_count = valid_count + 1;
    all_wechat_qts(:, :, valid_count) = wechat_qt;

    if valid_count > 1
        if ~isequal(wechat_qt, all_wechat_qts(:, :, 1))
            is_qt_consistent = false;
        end
    end
end

% 结果
fprintf('\n === 结果输出 ===\n');
fprintf('成功分析图片数量: %d / %d\n', valid_count, num_files);

if valid_count > 0
    if is_qt_consistent
        fprintf('\n 微信对这%d张图片使用了完全相同的量化表.\n', valid_count);
    else
        fprintf('\n 微信对不同图片使用了动态的量化表.\n');
        fprintf('这代表微信会根据图片复杂度调整压缩率，在J-Uniward-P中可能需要做极限防御处理.\n');
    end
    
    represent_qt = all_wechat_qts(:, :, 1);
    diff_qt = represent_qt - origin_qt;

    fprintf('\n=== 微信代表性量化表 ===\n');
    disp(represent_qt);
    fprintf('\n=== 差异矩阵(微信QT-原始QT) ===\n');
    disp('数值越大代表微信在该频率压缩细节越多:');
    disp(diff_qt);

    figure('Name', '微信压缩量化表分析', 'Position', [100, 100, 900, 400]);
    subplot(1, 3, 1);
    heatmap(origin_qt, 'Colormap', parula, 'CellLabelColor', 'none', 'Title', '原始量化表');
    subplot(1, 3, 2);
    heatmap(represent_qt, 'Colormap', parula, 'CellLabelColor', 'none', 'Title', '微信量化表');
    subplot(1, 3, 3);
    heatmap(diff_qt, 'Colormap', jet, 'Title', '差异矩阵(红色=重度破坏)');
else
    fprintf('没有成功分析任何图片，请确保wechat_downloaded文件夹里有图片.\n');
end
