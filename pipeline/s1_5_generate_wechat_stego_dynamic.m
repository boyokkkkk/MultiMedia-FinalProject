clear; clc; addpath(genpath(pwd));

qf_folder = 'qf752_0.2';
input_dir = fullfile('./data/wechat_test_covers', qf_folder);
output_dir = fullfile('./data/wechat_stego_out', qf_folder);
qt_db_path = fullfile('./data/', ['probed_qts_dict_', qf_folder, '.mat']);

if ~exist(output_dir, 'dir'), mkdir(output_dir); end

if ~exist(qt_db_path, 'file')
    error('找不到量化表字典 %s，请先运行 s0_5_extract_probed_qts.m', qt_db_path);
end
load(qt_db_path, 'qt_dict');
fprintf('>>> 成功加载微信QT映射字典，包含 %d 条记录。\n', qt_dict.Count);

files = dir(fullfile(input_dir, '*.jpg'));
if isempty(files)
    error('%s 目录下没有找到测试图片。', input_dir);
end

payload = 0.15; % 相对嵌入率
fprintf('>>> 开始生成载密图片，相对嵌入率 %f ...\n', payload);

for i = 1:length(files)
    if contains(files(i).name, 'stego'), continue; end
    
    img_name = files(i).name;
    img_path = fullfile(input_dir, img_name);
    
    if ~isKey(qt_dict, img_name)
        warning('  [%d/%d]: 跳过 %s，在字典中未找到对应的探测量化表。', i, length(files), img_name);
        continue;
    end
    
    fprintf('  [%d/%d]: 正在处理 %s ...\n', i, length(files), img_name);
    
    wechat_qt = qt_dict(img_name); % 动态获取专属 QT

    jpg = jpeg_read(img_path);
    coef = jpg.coef_arrays{1};
    qt_o = jpg.quant_tables{1};
    
    % 计算 J-Uniward 原始代价
    rho = get_juniward_cost(img_path);
    
    % J-Uniward-P 代价惩罚修正
    penalty = wechat_qt ./ qt_o;
    for r = 1:8
        for c = 1:8
            rho(r:8:end, c:8:end) = rho(r:8:end, c:8:end) * penalty(r, c);
        end
    end
    rho(1:8:end, 1:8:end) = 1e10; % 保护 DC 系数
    rho(coef == 0) = 1e10;        % 保护 0 交流系数
    
    % 模拟微信的量化过程，获取压缩后系数 C_coef
    [h, w] = size(coef);
    C_coef = zeros(h, w);
    for r = 1:8
        for c = 1:8
            mo = qt_o(r, c);
            mc = wechat_qt(r, c);
            C_coef(r:8:end, c:8:end) = round(coef(r:8:end, c:8:end) * mo / mc);
        end
    end
    
    % 计算需要嵌入的秘密信息长度
    total_nzAC = nnz(C_coef) - nnz(C_coef(1:8:end, 1:8:end));
    msg_len = round(total_nzAC * payload);
    msg_len = min(msg_len, 10000); % 安全上限
    msg = randi([0, 1], msg_len, 1);
    
    % 在模拟系数 C_coef 上使用 STC 嵌入
    S_coef = stc_embed(C_coef, rho, msg, payload);
    
    % 将修改逆推回发送端系数
    stego_coef = adjust_coefficients(coef, S_coef, qt_o, wechat_qt);
    stego_coef(stego_coef > 1023) = 1023;
    stego_coef(stego_coef < -1024) = -1024;
    
    % 写入并保存
    jpg.coef_arrays{1} = stego_coef;
    [~, name_base, ~] = fileparts(img_name);
    
    jpeg_write(jpg, fullfile(output_dir, [name_base, '_stego.jpg']));
    save(fullfile(output_dir, [name_base, '_data.mat']), 'msg', 'rho', 'payload', 'C_coef');
end

fprintf('>>> 动态 J-Uniward-P 隐写完成，结果保存在 %s\n', output_dir);