clear; clc;

qf_target = 100; % 在这里调整压缩画质
target_size = [512, 512];

boss_raw_dir = './data/BOSSbase_1.01';
boss_out_dir = './data/BOSSbase_qf100'; % 文件名也需要调整

ucid_raw_dir = './data/UCID-1338';
ucid_out_dir = './data/UCID_qf100'; % 文件名也需要调整

if ~exist(boss_out_dir, 'dir'), mkdir(boss_out_dir); end
if ~exist(ucid_out_dir, 'dir'), mkdir(ucid_out_dir); end

% --- 处理BOSSbase ---
disp('>>> 开始处理BOSSbase数据集(pgm->jpeg)...\n');
boss_files = dir(fullfile(boss_raw_dir, '*.pgm'));
for i = 1:length(boss_files)
    img_name = boss_files(i).name;
    img_path = fullfile(boss_raw_dir, img_name);
    img = imread(img_path);
    
    [~, name, ~] = fileparts(img_name);
    out_path = fullfile(boss_out_dir, [name, '.jpg']);

    imwrite(img, out_path, 'Quality', qf_target);

    if mod(i, 1000) == 0
        fprintf('已处理BOSSbase: %d / %d\n', i, length(boss_files));
    end
end

% 处理UCID
disp('>>> 开始处理UCID数据集(color->gray->resize->jpeg)...\n');
ucid_files = dir(fullfile(ucid_raw_dir, "*.*"));
ucid_files = ucid_files(~ismember({ucid_files.name}, {'.', '..'}));

for i = 1:length(ucid_files)
    img_name = ucid_files(i).name;
    img_path = fullfile(ucid_raw_dir, img_name);

    try
        img = imread(img_path);
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        if size(img, 1) ~= target_size(1) || size(img, 2) ~= target_size(2)
            img = imresize(img, target_size);
        end
        [~, name, ~] = fileparts(img_name);
        out_path = fullfile(ucid_out_dir, [name, '.jpg']);

        imwrite(img, out_path, 'Quality', qf_target);
    catch ME
        fprintf('警告: 无法读取图像%s, 跳过.原因: %s\n', img_name, ME.message);
    end

    if mod(i, 200) == 0
        fprintf('已处理UCID: %d / %d\n', i, length(ucid_files));
    end
end
disp('>>> 数据集清洗与格式化完成!');