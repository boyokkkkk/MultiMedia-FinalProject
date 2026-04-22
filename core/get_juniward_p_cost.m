function rho = get_juniward_p_cost(cover_jpg_path)
% J-Uniward-P 鲁棒代价计算
% 包含方向残差滤波 + 重新量化影响

    jpg = jpeg_read(cover_jpg_path);
    coef = jpg.coef_arrays{1};
    [H, W] = size(coef);
    img = double(imread(cover_jpg_path));
    
    % 滤波器
    lpdf = [-0.0544153492, 0.3125, 0.6875, -0.1875];
    hpdf = [-0.1875, -0.6875, 0.3125, 0.0544153492];
    
    F1 = lpdf'*hpdf; F2 = hpdf'*lpdf; F3 = hpdf'*hpdf;
    R1 = imfilter(img,F1,'symmetric');
    R2 = imfilter(img,F2,'symmetric');
    R3 = imfilter(img,F3,'symmetric');
    
    sgm = 1e-5;
    rho = zeros(H,W);
    
    for i = 1:H
        for j = 1:W
            c = coef(i,j);
            coef1 = coef; coef1(i,j) = c+1;
            img1 = block_idct(coef1);
            
            R1_1 = imfilter(img1,F1,'symmetric');
            R2_1 = imfilter(img1,F2,'symmetric');
            R3_1 = imfilter(img1,F3,'symmetric');
            
            d1 = mean(abs(R1_1-R1)./(abs(R1)+sgm));
            d2 = mean(abs(R2_1-R2)./(abs(R2)+sgm));
            d3 = mean(abs(R3_1-R3)./(abs(R3)+sgm));
            
            rho(i,j) = d1+d2+d3;
        end
    end
    rho(rho>1000)=1000;
end

function img = block_idct(coef)
    [H,W]=size(coef); img=zeros(H,W);
    for i=1:8:H for j=1:8:W
        img(i:i+7,j:j+7)=idct2(coef(i:i+7,j:j+7));
    end, end
end