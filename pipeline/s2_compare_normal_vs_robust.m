clear; clc; addpath(genpath(pwd));

qf_folder = 'qf100_jp';
normal_backup_dir = fullfile('./data/normal_stego_out', qf_folder);
robust_backup_dir = fullfile('./data/wechat_stego_out', qf_folder);
normal_wechat_dir = fullfile('./data/wechat_downloaded_normal', qf_folder);
robust_wechat_dir = fullfile('./data/wechat_downloaded', qf_folder);

normal_files = dir(fullfile(normal_wechat_dir, '*.jpg'));
robust_files = dir(fullfile(robust_wechat_dir, '*.jpg'));

if isempty(normal_files)
    error('普通算法微信回传目录为空：%s', normal_wechat_dir);
end
if isempty(robust_files)
    error('鲁棒算法微信回传目录为空：%s', robust_wechat_dir);
end

normal_map = containers.Map();
for i = 1:length(normal_files)
    normal_map(normal_files(i).name) = fullfile(normal_wechat_dir, normal_files(i).name);
end

robust_map = containers.Map();
for i = 1:length(robust_files)
    robust_map(robust_files(i).name) = fullfile(robust_wechat_dir, robust_files(i).name);
end

common_names = intersect(keys(normal_map), keys(robust_map));
if isempty(common_names)
    error('普通与鲁棒两组微信回传图片没有同名交集，请检查文件名。');
end

num_files = numel(common_names);
results = cell(num_files + 1, 6);
results(1, :) = {'文件名', '普通BER', '鲁棒BER', '普通链路状态', '鲁棒链路状态', '结论'};

normal_ber_list = nan(num_files, 1);
robust_ber_list = nan(num_files, 1);

for i = 1:num_files
    file_name = common_names{i};
    [~, base_name, ~] = fileparts(file_name);
    normal_mat = fullfile(normal_backup_dir, [strrep(base_name, '_stego', ''), '_data.mat']);
    robust_mat = fullfile(robust_backup_dir, [strrep(base_name, '_stego', ''), '_data.mat']);

    normal_status = 'ok';
    robust_status = 'ok';
    normal_ber = nan;
    robust_ber = nan;

    if exist(normal_mat, 'file')
        normal_data = load(normal_mat);
        [~, meta_normal] = extract_q_table(normal_map(file_name));
        if meta_normal.is_valid
            jpg_normal = jpeg_read(normal_map(file_name));
            coef_normal = double(jpg_normal.coef_arrays{1});
            msg_ext_normal = stc_extract(coef_normal, normal_data.coef, normal_data.rhoP1, normal_data.payload, normal_data.rhoM1);
            compare_len = min(length(normal_data.msg), length(msg_ext_normal));
            if compare_len > 0
                normal_ber = sum(xor(normal_data.msg(1:compare_len), msg_ext_normal(1:compare_len))) / compare_len;
            else
                normal_status = '无有效提取长度';
            end
        else
            normal_status = meta_normal.reason;
        end
    else
        normal_status = '缺少备份mat';
    end

    if exist(robust_mat, 'file')
        robust_data = load(robust_mat);
        [~, meta_robust] = extract_q_table(robust_map(file_name));
        if meta_robust.is_valid
            jpg_robust = jpeg_read(robust_map(file_name));
            coef_robust = double(jpg_robust.coef_arrays{1});
            msg_ext_robust = stc_extract(coef_robust, robust_data.best_C_coef, robust_data.best_rhoP1, robust_data.payload, robust_data.best_rhoM1);
            compare_len = min(length(robust_data.best_msg), length(msg_ext_robust));
            if compare_len > 0
                robust_ber = sum(xor(robust_data.best_msg(1:compare_len), msg_ext_robust(1:compare_len))) / compare_len;
            else
                robust_status = '无有效提取长度';
            end
        else
            robust_status = meta_robust.reason;
        end
    else
        robust_status = '缺少备份mat';
    end

    normal_ber_list(i) = normal_ber;
    robust_ber_list(i) = robust_ber;

    if ~isnan(normal_ber) && ~isnan(robust_ber)
        if robust_ber < normal_ber
            conclusion = '鲁棒版更优';
        elseif robust_ber > normal_ber
            conclusion = '普通版更优';
        else
            conclusion = '两者相同';
        end
    else
        conclusion = '存在异常链路或缺失数据';
    end

    results(i + 1, :) = {file_name, normal_ber, robust_ber, normal_status, robust_status, conclusion};
end

fprintf('\n=== 普通 J-Uniward vs 鲁棒 J-Uniward-P 对比结果 ===\n');
for i = 2:size(results, 1)
    fprintf('%s | 普通BER=%.4f | 鲁棒BER=%.4f | %s\n', ...
        string(results{i,1}), results{i,2}, results{i,3}, string(results{i,6}));
end

valid_normal = normal_ber_list(~isnan(normal_ber_list));
valid_robust = robust_ber_list(~isnan(robust_ber_list));
if ~isempty(valid_normal)
    fprintf('\n普通版平均 BER = %.4f\n', mean(valid_normal));
end
if ~isempty(valid_robust)
    fprintf('鲁棒版平均 BER = %.4f\n', mean(valid_robust));
end

save(fullfile('./data', ['compare_normal_vs_robust_', qf_folder, '.mat']), 'results', 'normal_ber_list', 'robust_ber_list');
