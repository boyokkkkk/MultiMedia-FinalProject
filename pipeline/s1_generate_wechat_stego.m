clear; clc; addpath(genpath(pwd));

qf_folder = 'qf100';
input_dir = fullfile('./data/wechat_test_covers', qf_folder);
output_dir = fullfile('./data/wechat_stego_out', qf_folder);
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

files = dir(fullfile(input_dir, '*.jpg'));
if isempty(files)
    error('%s 该路径下没有图片, 当前所在目录是 %s', input_dir, pwd);
end
payload = 0.2; % 预先设为0.1
fprintf('>>> 成功找到 %d 张测试图片，准备开始嵌入...\n', length(files));


for i = 1:length(files)
    if contains(files(i).name, 'stego'), continue; end 
    
    fprintf('正在处理 [%d/%d]: %s ...\n', i, length(files), files(i).name);

    img_path = fullfile(input_dir, files(i).name);

    jpg = jpeg_read(img_path);
    coef = jpg.coef_arrays{1};
    
    % % 使用复现J-Uniward算法计算代价
    % rho = get_juniward_cost(img_path);
    % 
    % % 生成随机信息
    % total_nzAC = nnz(coef) - nnz(coef(1:8:end, 1:8:end));
    % msg_len = round(total_nzAC * payload);
    % msg = randi([0, 1], msg_len, 1);
    % 
    % % STC嵌入
    % stego_coef = stc_embed(coef, rho, msg, payload);

    % ---------------------------------------------------------
    % 如果要J-Uniward-P 使用test_a逻辑
    % ---------------------------------------------------------
    % QF=100的量化表
    wechat_qt = [
         8     5     5     8    12    19    24    29;
         6     6     7     9    12    28    29    26;
         7     6     8    12    19    27    33    27;
         7     8    11    14    24    42    38    30;
         9    11    18    27    33    52    49    37;
        12    17    26    31    39    50    54    44;
        24    31    37    42    49    58    58    48;
        35    44    46    47    54    48    49    48
    ];
    qt_o = jpg.quant_tables{1};
    rho = get_juniward_cost(img_path);
    penalty = wechat_qt ./ qt_o;
    for r = 1:8
        for c = 1:8
            rho(r:8:end, c:8:end) = rho(r:8:end, c:8:end) * penalty(r, c);
        end
    end
    rho(1:8:end, 1:8:end) = 1e10; 
    rho(coef == 0) = 1e10;

    % 内存模拟微信信道压缩
    [h, w] = size(coef);
    C_coef = zeros(h, w);
    for r = 1:8
        for c = 1:8
            mo = qt_o(r, c);
            mc = wechat_qt(r, c);
            C_coef(r:8:end, c:8:end) = round(coef(r:8:end, c:8:end) * mo / mc);
        end
    end
    % 计算可嵌入容量
    total_nzAC = nnz(C_coef) - nnz(C_coef(1:8:end, 1:8:end));
    msg_len = round(total_nzAC * payload);
    msg_len = min(msg_len, 10000);
    msg = randi([0, 1], msg_len, 1);
    
    % C_coef模拟嵌入STC
    S_coef = stc_embed(C_coef, rho, msg, payload);
    stego_coef = adjust_coefficients(coef, S_coef, qt_o, wechat_qt);
    stego_coef(stego_coef > 1023) = 1023;
    stego_coef(stego_coef < -1024) = -1024;
    
    % 保存载密后的图片
    jpg.coef_arrays{1} = stego_coef;
    [~, name, ~] = fileparts(files(i).name);
    
    jpeg_write(jpg, fullfile(output_dir, [name, '_stego.jpg']));
    save(fullfile(output_dir, [name, '_data.mat']), 'msg', 'rho', 'payload', 'C_coef');
end

fprintf('>>> 全部测试图片已嵌入并备份到 %s, 请发往微信...\n', output_dir);