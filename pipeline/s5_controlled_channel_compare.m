clear; clc; close all;
rng(0);
addpath(genpath(pwd));

input_dir = './data/wechat_test_covers/qf100_jp';
work_dir  = './data/tmp';
if ~exist(work_dir,'dir'), mkdir(work_dir); end

files = dir(fullfile(input_dir,'*.jpg'));
files = files(1:min(100,length(files)));

Qo_set = [100,95];
Qc_set = [95,75];
payload = 0.1;

BER_n = zeros(2,length(files));
BER_r = zeros(2,length(files));

for case_idx = 1:2

    Qo = Qo_set(case_idx);
    Qc = Qc_set(case_idx);

    fprintf('\n==== Qo=%d Qc=%d ====\n',Qo,Qc);

    for i = 1:length(files)

        % ===== 原图 =====
        I = imread(fullfile(input_dir,files(i).name));
        I = imresize(I,[256,256]);

        % ===== Qo =====
        imwrite(I,'tmp_Qo.jpg','Quality',Qo);

        % ===== Qc =====
        imwrite(imread('tmp_Qo.jpg'),'tmp_Qc.jpg','Quality',Qc);

        % ================= 普通 =================
        rho_n = get_juniward_cost('tmp_Qc.jpg');
        BER_n(case_idx,i) = embed_extract('tmp_Qc.jpg',rho_n,payload,Qc);

        % ================= P =================
        rho_p = get_juniward_p_cost('tmp_Qc.jpg'); % ⚠️ 注意：论文复现用 Qc

        BER_r(case_idx,i) = embed_extract('tmp_Qc.jpg',rho_p,payload,Qc);

        fprintf('[%d] %.4f | %.4f\n',i,BER_n(case_idx,i),BER_r(case_idx,i));
    end
end

% ===== 输出 =====
fprintf('\n===== Table I =====\n');
for k=1:2
    fprintf('Qo=%d Qc=%d | J-UNIWARD %.4f | J-UNIWARD-P %.4f\n',...
        Qo_set(k),Qc_set(k),mean(BER_n(k,:)),mean(BER_r(k,:)));
end