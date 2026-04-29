clear; clc; addpath(genpath(pwd));

qf_folder = 'qf752_0.2';
% 第一次通过微信传输并下载下来的【原图】存放路径
probed_dir = fullfile('./data/wechat_probed_covers', qf_folder); 
% 字典保存路径
db_out_path = fullfile('./data/', ['probed_qts_dict_', qf_folder, '.mat']);

files = dir(fullfile(probed_dir, '*.jpg'));
if isempty(files)
    error('未找到探测图片，请确保已将原图经过微信传输并保存在 %s', probed_dir);
end

fprintf('>>> 正在提取 %d 张探测图片的微信真实量化表(QT)...\n', length(files));
qt_dict = containers.Map('KeyType', 'char', 'ValueType', 'any');

for i = 1:length(files)
    img_name = files(i).name;
    img_path = fullfile(probed_dir, img_name);
    
    try
        jpg = jpeg_read(img_path);
        qt_dict(img_name) = jpg.quant_tables{1}; 
    catch ME
        warning('读取 %s 失败: %s', img_name, ME.message);
    end
end

save(db_out_path, 'qt_dict');
fprintf('>>> 提取完成！QT映射字典已保存至: %s\n', db_out_path);