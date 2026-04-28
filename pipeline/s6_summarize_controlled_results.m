clear; clc; addpath(genpath(pwd));

% 论文风格结果汇总脚本：
% - 汇总受控信道实验中普通 J-UNIWARD 与鲁棒 J-UNIWARD-P 的逐图结果
% - 生成更接近论文表格的控制台输出
% - 保存可直接用于后续整理报告的 summary_table / aggregate_stats

qf_folder = 'qf100_jp';
work_dir = fullfile('./data/controlled_channel_compare', qf_folder);
summary_mat_path = fullfile(work_dir, 'controlled_channel_summary.mat');
summary_csv_path = fullfile(work_dir, 'controlled_channel_summary_table.csv');
summary_xlsx_path = fullfile(work_dir, 'controlled_channel_summary_table.xlsx');
summary_out_path = fullfile(work_dir, 'controlled_channel_paper_summary.mat');

if ~exist(work_dir, 'dir')
    error('结果目录不存在：%s', work_dir);
end

summary_rows = {};
payload = nan;
Qc = nan;

if exist(summary_mat_path, 'file')
    S = load(summary_mat_path);
    if isfield(S, 'results')
        raw_results = S.results;
        if size(raw_results, 1) >= 2
            for i = 2:size(raw_results, 1)
                if isempty(raw_results{i, 1})
                    continue;
                end
                summary_rows(end + 1, :) = raw_results(i, :); %#ok<AGROW>
            end
        end
    end
    if isfield(S, 'payload')
        payload = S.payload;
    end
    if isfield(S, 'Qc')
        Qc = S.Qc;
    end
end

if isempty(summary_rows)
    compare_files = dir(fullfile(work_dir, '*_controlled_compare.mat'));
    if isempty(compare_files)
        error('未找到 controlled_channel_summary.mat，也未找到 *_controlled_compare.mat。请先运行 s5_controlled_channel_compare.m');
    end

    for i = 1:length(compare_files)
        data = load(fullfile(work_dir, compare_files(i).name));
        base_name = compare_files(i).name;
        base_name = strrep(base_name, '_controlled_compare.mat', '.jpg');

        ber_normal = get_field_or_nan(data, 'ber_normal');
        ber_robust = get_field_or_nan(data, 'ber_robust');
        keep_rate_normal = get_field_or_nan(data, 'keep_rate_normal');
        keep_rate_robust = get_field_or_nan(data, 'keep_rate_robust');

        if isfield(data, 'O_coef') && isfield(data, 'S_normal')
            change_count_normal = sum(data.O_coef(:) ~= data.S_normal(:));
        else
            change_count_normal = nan;
        end

        if isfield(data, 'O_coef') && isfield(data, 'S_robust')
            change_count_robust = sum(data.O_coef(:) ~= data.S_robust(:));
        else
            change_count_robust = nan;
        end

        conclusion = compare_conclusion(ber_normal, ber_robust, keep_rate_normal, keep_rate_robust);
        summary_rows(end + 1, :) = {base_name, ber_normal, ber_robust, keep_rate_normal, keep_rate_robust, change_count_normal, change_count_robust, conclusion}; %#ok<AGROW>

        if isnan(payload) && isfield(data, 'payload')
            payload = data.payload;
        end
        if isnan(Qc) && isfield(data, 'Qc')
            Qc = data.Qc;
        end
    end
end

if isempty(summary_rows)
    error('没有可汇总的实验结果。');
end

num_rows = size(summary_rows, 1);
file_names = strings(num_rows, 1);
normal_ber = nan(num_rows, 1);
robust_ber = nan(num_rows, 1);
normal_keep = nan(num_rows, 1);
robust_keep = nan(num_rows, 1);
normal_changes = nan(num_rows, 1);
robust_changes = nan(num_rows, 1);
ber_gain = nan(num_rows, 1);
keep_gain = nan(num_rows, 1);
change_ratio = nan(num_rows, 1);
win_flag = strings(num_rows, 1);

for i = 1:num_rows
    file_names(i) = string(summary_rows{i, 1});
    normal_ber(i) = to_numeric(summary_rows{i, 2});
    robust_ber(i) = to_numeric(summary_rows{i, 3});
    normal_keep(i) = to_numeric(summary_rows{i, 4});
    robust_keep(i) = to_numeric(summary_rows{i, 5});
    normal_changes(i) = to_numeric(summary_rows{i, 6});
    robust_changes(i) = to_numeric(summary_rows{i, 7});

    if ~isnan(normal_ber(i)) && ~isnan(robust_ber(i))
        ber_gain(i) = normal_ber(i) - robust_ber(i);
    end
    if ~isnan(normal_keep(i)) && ~isnan(robust_keep(i))
        keep_gain(i) = robust_keep(i) - normal_keep(i);
    end
    if ~isnan(normal_changes(i)) && normal_changes(i) ~= 0 && ~isnan(robust_changes(i))
        change_ratio(i) = robust_changes(i) / normal_changes(i);
    end

    if ~isnan(ber_gain(i))
        if ber_gain(i) > 1e-12
            win_flag(i) = "Robust";
        elseif ber_gain(i) < -1e-12
            win_flag(i) = "Normal";
        else
            win_flag(i) = "Tie";
        end
    elseif ~isnan(keep_gain(i))
        if keep_gain(i) > 1e-12
            win_flag(i) = "Robust(Keep)";
        elseif keep_gain(i) < -1e-12
            win_flag(i) = "Normal(Keep)";
        else
            win_flag(i) = "Undecided";
        end
    else
        win_flag(i) = "Undecided";
    end
end

summary_table = table(file_names, normal_ber, robust_ber, ber_gain, ...
    normal_keep, robust_keep, keep_gain, ...
    normal_changes, robust_changes, change_ratio, win_flag, ...
    'VariableNames', {'Image', 'BER_Normal', 'BER_Robust', 'BER_Gain', ...
    'Keep_Normal', 'Keep_Robust', 'Keep_Gain', ...
    'Changes_Normal', 'Changes_Robust', 'Change_Ratio', 'Winner'});

valid_normal_ber = normal_ber(~isnan(normal_ber));
valid_robust_ber = robust_ber(~isnan(robust_ber));
valid_ber_gain = ber_gain(~isnan(ber_gain));
valid_normal_keep = normal_keep(~isnan(normal_keep));
valid_robust_keep = robust_keep(~isnan(robust_keep));
valid_keep_gain = keep_gain(~isnan(keep_gain));
valid_change_ratio = change_ratio(~isnan(change_ratio));

aggregate_stats = struct();
aggregate_stats.qf_folder = qf_folder;
aggregate_stats.payload = payload;
aggregate_stats.Qc = Qc;
aggregate_stats.num_images = num_rows;
aggregate_stats.mean_ber_normal = safe_mean(valid_normal_ber);
aggregate_stats.mean_ber_robust = safe_mean(valid_robust_ber);
aggregate_stats.mean_ber_gain = safe_mean(valid_ber_gain);
aggregate_stats.median_ber_gain = safe_median(valid_ber_gain);
aggregate_stats.mean_keep_normal = safe_mean(valid_normal_keep);
aggregate_stats.mean_keep_robust = safe_mean(valid_robust_keep);
aggregate_stats.mean_keep_gain = safe_mean(valid_keep_gain);
aggregate_stats.mean_change_ratio = safe_mean(valid_change_ratio);
aggregate_stats.robust_win_count = sum(win_flag == "Robust" | win_flag == "Robust(Keep)");
aggregate_stats.normal_win_count = sum(win_flag == "Normal" | win_flag == "Normal(Keep)");
aggregate_stats.tie_count = sum(win_flag == "Tie");
aggregate_stats.undecided_count = sum(win_flag == "Undecided");

fprintf('\n================ 受控信道论文风格结果汇总 ================\n');
if ~isnan(payload)
    fprintf('Payload = %.4f bpnzAC\n', payload);
end
if ~isnan(Qc)
    fprintf('Channel Qc = %g\n', Qc);
end
fprintf('样本数 = %d\n\n', num_rows);

fprintf('%-24s %-10s %-10s %-10s %-10s %-10s\n', 'Image', 'BER-N', 'BER-R', 'ΔBER', 'Keep-N', 'Keep-R');
for i = 1:height(summary_table)
    fprintf('%-24s %-10.4f %-10.4f %-10.4f %-10.4f %-10.4f\n', ...
        char(summary_table.Image(i)), ...
        summary_table.BER_Normal(i), ...
        summary_table.BER_Robust(i), ...
        summary_table.BER_Gain(i), ...
        summary_table.Keep_Normal(i), ...
        summary_table.Keep_Robust(i));
end

fprintf('\n---------------- 聚合统计 ----------------\n');
fprintf('Mean BER (Normal) : %.4f\n', aggregate_stats.mean_ber_normal);
fprintf('Mean BER (Robust) : %.4f\n', aggregate_stats.mean_ber_robust);
fprintf('Mean ΔBER         : %.4f (正值表示鲁棒版更优)\n', aggregate_stats.mean_ber_gain);
fprintf('Median ΔBER       : %.4f\n', aggregate_stats.median_ber_gain);
fprintf('Mean Keep (Normal): %.4f\n', aggregate_stats.mean_keep_normal);
fprintf('Mean Keep (Robust): %.4f\n', aggregate_stats.mean_keep_robust);
fprintf('Mean ΔKeep        : %.4f\n', aggregate_stats.mean_keep_gain);
fprintf('Mean ChangeRatio  : %.4f\n', aggregate_stats.mean_change_ratio);
fprintf('Robust wins       : %d\n', aggregate_stats.robust_win_count);
fprintf('Normal wins       : %d\n', aggregate_stats.normal_win_count);
fprintf('Ties              : %d\n', aggregate_stats.tie_count);
fprintf('Undecided         : %d\n', aggregate_stats.undecided_count);

save(summary_out_path, 'summary_table', 'aggregate_stats', 'summary_rows');

try
    writetable(summary_table, summary_csv_path);
catch ME
    fprintf('写出 CSV 失败：%s\n', ME.message);
end

try
    writetable(summary_table, summary_xlsx_path);
catch ME
    fprintf('写出 XLSX 失败：%s\n', ME.message);
end

fprintf('\n>>> 汇总完成，已保存到：%s\n', summary_out_path);

function v = get_field_or_nan(S, field_name)
if isfield(S, field_name)
    v = S.(field_name);
else
    v = nan;
end
end

function v = to_numeric(x)
if isnumeric(x)
    if isempty(x)
        v = nan;
    else
        v = double(x(1));
    end
elseif islogical(x)
    v = double(x(1));
elseif isstring(x) || ischar(x)
    v = str2double(string(x));
    if isnan(v)
        v = nan;
    end
else
    v = nan;
end
end

function m = safe_mean(x)
if isempty(x)
    m = nan;
else
    m = mean(x);
end
end

function m = safe_median(x)
if isempty(x)
    m = nan;
else
    m = median(x);
end
end

function conclusion = compare_conclusion(ber_normal, ber_robust, keep_normal, keep_robust)
if ~isnan(ber_normal) && ~isnan(ber_robust)
    if ber_robust < ber_normal
        conclusion = '鲁棒版近似BER更低';
    elseif ber_robust > ber_normal
        conclusion = '普通版近似BER更低';
    else
        conclusion = '两者近似BER相同';
    end
elseif ~isnan(keep_normal) && ~isnan(keep_robust)
    if keep_robust > keep_normal
        conclusion = '鲁棒版保持率更高';
    elseif keep_robust < keep_normal
        conclusion = '普通版保持率更高';
    else
        conclusion = '两者保持率相同';
    end
else
    conclusion = '结果不足以判断';
end
end
