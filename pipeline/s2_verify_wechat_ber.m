clear; clc; addpath(genpath(pwd));

qf_folder = 'qf100_jp';
wechat_dir = fullfile('./data/wechat_downloaded/', qf_folder);
backup_dir = fullfile('./data/wechat_stego_out/', qf_folder);
files = dir(fullfile(wechat_dir, '*.jpg'));

if isempty(files)
    error('%s 该路径下没有图片, 当前所在目录是 %s', wechat_dir, pwd);
end
fprintf('>>> 成功找到 %d 张测试图片，准备开始计算BER...\n', length(files));

ber_results = zeros(length(files), 1);
valid_count = 0;

for i = 1:length(files)
    wechat_name = files(i).name;
    name_base = strrep(wechat_name, '.jpg', '');
    
    % 兼容两种命名：xxx_stego.jpg 或 xxx.jpg（微信下载后可能改名）
    mat_name = strrep(name_base, '_stego', '');
    mat_path = fullfile(backup_dir, [mat_name, '_data.mat']);
    
    if ~exist(mat_path, 'file')
        fprintf('[跳过] 找不到 %s 对应的备份信息: %s\n', wechat_name, mat_path);
        continue;
    end

    load(mat_path, 'msg', 'rho', 'payload', 'C_coef');
    fprintf('正在处理 [%d/%d]: %s ...\n', i, length(files), files(i).name);
    
    % 读取微信压缩后的DCT系数
    jpg_wechat = jpeg_read(fullfile(wechat_dir, wechat_name));
    wechat_coef = jpg_wechat.coef_arrays{1};
    
    % 提取STC（cover=C_coef，即嵌入前的模拟信道系数）
    msg_ext = stc_extract(wechat_coef, C_coef, rho, payload);
    
    % 计算BER
    compare_len = min(length(msg), length(msg_ext));
    ber = sum(xor(msg(1:compare_len), msg_ext(1:compare_len))) / compare_len;
    
    valid_count = valid_count + 1;
    ber_results(valid_count) = ber;
    fprintf('  图片: %-30s | BER = %.4f\n', wechat_name, ber);
end

%% ===== 汇总输出 =====
fprintf('\n============================================================\n');
fprintf('>>> 微信真实信道 BER 汇总 (qf_folder = %s)\n', qf_folder);
fprintf('============================================================\n');
fprintf('有效测试图片数: %d\n', valid_count);
if valid_count > 0
    ber_valid = ber_results(1:valid_count);
    fprintf('平均 BER     : %.6f\n', mean(ber_valid));
    fprintf('最大 BER     : %.6f\n', max(ber_valid));
    fprintf('最小 BER     : %.6f\n', min(ber_valid));
    fprintf('BER=0 图片数 : %d / %d (完美提取)\n', sum(ber_valid == 0), valid_count);
else
    fprintf('没有有效结果，请检查 wechat_downloaded 文件夹是否有图片。\n');
end
fprintf('============================================================\n');