clear; clc; close all;
rng(0); % 固定随机种子，保证可复现
addpath('utils');
addpath('core');
addpath(genpath(pwd));

if ~exist('result', 'dir')
    mkdir('result');
end

%% ===================== 实验参数（和论文完全一致）=====================
dataset_path = 'data/BOSSbase_1.01/'; % 本地数据集路径
img_list = dir(fullfile(dataset_path, '*.pgm'));
img_list = img_list(1:2); % 论文：随机1000张（这里取前1000）

Qo_set = [100, 95];        % 原始质量
Qc_set = [95, 75];         % 信道质量
payload = 0.1;        %  0.05:0.1:0.2:0.3:0.4:0.5 

% 保存 BER
BER_normal = zeros(2, length(img_list));
BER_robust = zeros(2, length(img_list));

%% ===================== 批量实验开始 =====================
for case_idx = 1:2
    Qo = Qo_set(case_idx);
    Qc = Qc_set(case_idx);
    fprintf('======== 开始实验 Qo=%d, Qc=%d ========\n', Qo, Qc);

    for img_idx = 1:length(img_list)
        % 0. 读原图
        img_path = fullfile(dataset_path, img_list(img_idx).name);
        I = imread(img_path);
        I = imresize(I, [128, 128]); % 论文标准尺寸

        % 1. 生成 Qo 图像
        imwrite(I, 'result/cover_Qo.jpg', 'Quality', Qo);
      
        % 2. 生成信道压缩 Qc 图像
        I_qo = imread('result/cover_Qo.jpg');
        imwrite(I_qo, 'result/channel_Qc.jpg', 'Quality', Qc);
        
        % ========== 算法1：传统 J-UNIWARD ==========
        rho_normal = get_juniward_cost('result/channel_Qc.jpg');
        [ber_normal] = embed_extract('result/channel_Qc.jpg', rho_normal, payload, Qc);
        
        % ========== 算法2：鲁棒 J-UNIWARD-P ==========
        rho_robust = get_juniward_p_cost('result/channel_Qc.jpg');
        [ber_robust] = robust_embed_extract('result/cover_Qo.jpg', 'result/channel_Qc.jpg', rho_robust, payload, Qo, Qc);
        
        % 保存 BER
        BER_normal(case_idx, img_idx) = ber_normal;
        BER_robust(case_idx, img_idx) = ber_robust;
        
        fprintf('  第 %d 张 | 传统BER = %.4f | 鲁棒BER = %.4f\n', ...
            img_idx, ber_normal, ber_robust);
    end
end

%% ===================== 输出论文 Table I =====================
fprintf('\n===================== 论文 Table I 复现结果 =====================\n');
fprintf('数据集：BOSSbase-1.01  1000张512×512\n');
fprintf('------------------------------------------------------------\n');
fprintf('设置        | 算法          | 平均BER\n');
fprintf('------------------------------------------------------------\n');

alg_names = {'J-UNIWARD', 'J-UNIWARD-P'};
for case_idx = 1:2
    Qo = Qo_set(case_idx);
    Qc = Qc_set(case_idx);
    for alg_idx = 1:2
    ber_mean_normal = mean(BER_normal(case_idx, :));
    ber_mean_robust = mean(BER_robust(case_idx, :));
    
    fprintf(' Qo=%d Qc=%d | %-13s | %.6f\n', Qo, Qc, alg_names{1}, ber_mean_normal);
    fprintf(' Qo=%d Qc=%d | %-13s | %.6f\n', Qo, Qc, alg_names{2}, ber_mean_robust);
    end
end
fprintf('---------------------------------------------------------------\n');