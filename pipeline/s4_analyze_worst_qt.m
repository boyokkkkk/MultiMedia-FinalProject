clear; clc; addpath(genpath(pwd));

wechat_dir = './data/wechat_downloaded/qf100_jp';
files = dir(fullfile(wechat_dir, '*.jpg'));

if isempty(files)
    error('该路径下找不到图片...');
end

valid_qts = [];
invalid_files = {};

fprintf('正在分析 %d 张微信量化表...\n', length(files));
for i = 1:length(files)
    img_path = fullfile(wechat_dir, files(i).name);
    [qt, meta] = extract_q_table(img_path);
    if meta.is_valid
        if isempty(valid_qts)
            valid_qts = zeros(8, 8, 0);
        end
        valid_qts(:, :, end + 1) = qt; %#ok<SAGROW>
    else
        invalid_files{end + 1} = sprintf('%s | %s', files(i).name, meta.reason); %#ok<AGROW>
    end
end

if isempty(valid_qts)
    fprintf('没有可用于建模的有效JPEG量化表。\n');
else
    worst_case_qt = max(valid_qts, [], 3); % 取最大
    fprintf('最差情况微信QT矩阵\n');
    disp(worst_case_qt);
end

if ~isempty(invalid_files)
    fprintf('\n以下文件属于异常链路，不应再按JPEG量化表建模：\n');
    for i = 1:numel(invalid_files)
        fprintf('%s\n', invalid_files{i});
    end
end
