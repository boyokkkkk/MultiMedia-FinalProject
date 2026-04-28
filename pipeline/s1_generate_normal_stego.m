clear; clc; addpath(genpath(pwd));

qf_folder = 'qf100_jp';
input_dir = fullfile('./data/wechat_test_covers', qf_folder);
output_dir = fullfile('./data/normal_stego_out', qf_folder);
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

files = dir(fullfile(input_dir, '*.jpg'));
if isempty(files)
    error('%s 该路径下没有图片, 当前所在目录是 %s', input_dir, pwd);
end
payload = 0.2;
fprintf('>>> 成功找到 %d 张测试图片，准备生成普通 J-Uniward stego...\n', length(files));

% -------- MEX 预检查 --------
which_jpeg_read = which('jpeg_read');
which_jpeg_write = which('jpeg_write');
fprintf('jpeg_read 路径: %s\n', which_jpeg_read);
fprintf('jpeg_write 路径: %s\n', which_jpeg_write);
if isempty(which_jpeg_read) || isempty(which_jpeg_write)
    error('未找到 jpeg_read / jpeg_write MEX 文件。');
end

% 先用第一张图做最小化MEX探测，尽量在正式循环前暴露问题
probe_path = fullfile(input_dir, files(1).name);
fprintf('>>> 正在执行 MEX 探测: %s\n', probe_path);
probe_info = imfinfo(probe_path);
fprintf('探测图像尺寸: %dx%d, ColorType=%s\n', probe_info.Width, probe_info.Height, probe_info.ColorType);
fprintf('注意：如果 MATLAB 在下一步直接闪退，基本可判定是 jpeg_read.mexw64 与当前 MATLAB 版本或该 JPEG 不兼容。\n');
probe_jpg = jpeg_read(probe_path); %#ok<NASGU>
fprintf('>>> MEX 探测通过，开始正式生成。\n');

for i = 1:length(files)
    if contains(files(i).name, 'stego'), continue; end

    fprintf('正在处理 [%d/%d]: %s ...\n', i, length(files), files(i).name);
    img_path = fullfile(input_dir, files(i).name);

    img_info = imfinfo(img_path);
    fprintf('  图像信息: %dx%d, ColorType=%s\n', img_info.Width, img_info.Height, img_info.ColorType);

    try
        jpg = jpeg_read(img_path);
    catch ME
        fprintf('读取 JPEG 结构失败 %s：%s\n', files(i).name, ME.message);
        continue;
    end
    coef = double(jpg.coef_arrays{1});

    try
        [rho, rhoP1, rhoM1] = get_juniward_cost(img_path);
    catch ME
        fprintf('计算 %s 的 J-Uniward 代价失败：%s\n', files(i).name, ME.message);
        continue;
    end

    rho(~isfinite(rho)) = 1e10;
    rho(1:8:end, 1:8:end) = 1e10;
    rho(coef == 0) = 1e10;

    total_nzAC = nnz(coef) - nnz(coef(1:8:end, 1:8:end));
    msg_len = round(total_nzAC * payload);
    msg_len = min(msg_len, 10000);
    if msg_len <= 0
        fprintf('图片 %s 无有效嵌入容量，跳过。\n', files(i).name);
        continue;
    end

    rng(2000 + i);
    msg = randi([0, 1], msg_len, 1);

    try
        [stego_coef, sim_info] = stc_embed(coef, rhoP1, msg, payload, rhoM1);
    catch ME
        fprintf('嵌入 %s 失败：%s\n', files(i).name, ME.message);
        continue;
    end

    stego_coef(stego_coef > 1023) = 1023;
    stego_coef(stego_coef < -1024) = -1024;

    jpg.coef_arrays{1} = double(stego_coef);
    [~, name, ~] = fileparts(files(i).name);

    fprintf('  正在写出 stego: %s\n', fullfile(output_dir, [name, '_stego.jpg']));
    jpeg_write(jpg, fullfile(output_dir, [name, '_stego.jpg']));

    save(fullfile(output_dir, [name, '_data.mat']), ...
        'msg', 'rho', 'rhoP1', 'rhoM1', 'sim_info', 'payload', 'coef');
end

fprintf('>>> 普通 J-Uniward stego 已生成并保存到 %s\n', output_dir);
