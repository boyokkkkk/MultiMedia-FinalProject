clear; clc;

% 1. 加载你在 s0_5 中获取的【探测字典】
load('./data/probed_qts_dict_qf752_0.2.mat'); 

% 2. 指定微信下载的【载密图片】路径
wechat_stego_dir = './data/wechat_downloaded/qf752_0.2';
stego_files = dir(fullfile(wechat_stego_dir, '*_stego.jpg'));

fprintf('>>> 开始对比 QT 矩阵变化...\n\n');

for i = 1:min(10, length(stego_files)) % 先看前3张
    stego_name = stego_files(i).name;
    % 推导出原图的名字 (把 _stego 去掉)
    origin_name = strrep(stego_name, '_stego', ''); 
    
    % 读取这图在微信里的现状
    stego_jpg = jpeg_read(fullfile(wechat_stego_dir, stego_name));
    stego_qt = stego_jpg.quant_tables{1};
    
    if isKey(qt_dict, origin_name)
        % 取出它在 s0_5 里记录的无密状态下的 QT
        probed_qt = qt_dict(origin_name); 
        
        fprintf('--- 图像: %s ---\n', origin_name);
        if isequal(stego_qt, probed_qt)
            disp('结论: 完美匹配！微信没有因为隐写改变这块信道。');
        else
            disp('结论: 糟糕！QT 发生了变化 (发生了重压缩降级)。');
            disp('【探测到的原始 QT】:');
            disp(probed_qt);
            disp('【携带隐写后，微信实际分配的新 QT】:');
            disp(stego_qt);
        end
        fprintf('\n');
    end
end