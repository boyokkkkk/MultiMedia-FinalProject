clear; clc; addpath(genpath(pwd));

qf_folder = 'qf100_jp';
wechat_dir = fullfile('./data/wechat_downloaded/', qf_folder);
backup_dir = fullfile('./data/wechat_stego_out/', qf_folder);
files = dir(fullfile(wechat_dir, '*.jpg'));

if isempty(files)
    error('%s 该路径下没有图片, 当前所在目录是 %s', input_dir, pwd);
end
fprintf('>>> 成功找到 %d 张测试图片，准备开始计算BER...\n', length(files));

ber_results = zeros(length(files), 1);

for i = 1:length(files)
    wechat_name = files(i).name;
    name_base = strrep(wechat_name, '.jpg', '');
    
    mat_path = fullfile(backup_dir, [strrep(name_base, '_stego', ''), '_data.mat']);
    
    if ~exist(mat_path, 'file')
        fprintf('找不到 %s 对应的备份信息 跳过\n', wechat_name);
        continue;
    end

    load(mat_path); 
    fprintf('正在处理 [%d/%d]: %s ...\n', i, length(files), files(i).name);
    
    % 读取微信压缩后的DCT矩阵
    jpg_wechat = jpeg_read(fullfile(wechat_dir, wechat_name));
    wechat_coef = jpg_wechat.coef_arrays{1};
    
    % 提取STC
    msg_ext = stc_extract(wechat_coef, C_coef, rho, payload);
    
    % 计算BER
    compare_len = min(length(msg), length(msg_ext));
    ber = sum(xor(msg(1:compare_len), msg_ext(1:compare_len))) / compare_len;
    
    ber_results(i) = ber;
    fprintf('图片: %s | BER = %.4f\n', wechat_name, ber);
end