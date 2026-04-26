function rho = get_juniward_cost(cover_jpg)
    % J-Uniward 方向残差代价计算
    % 使用 Image Processing Toolbox 官方函数：imfilter, imresize
    
    % 1. 读取 JPEG
    jpg = jpeg_read(cover_jpg);
    coef = jpg.coef_arrays{1};
    img = imread(cover_jpg);
    
    % 自动转灰度
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    img = double(img);

    % J-Uniward 标准小波滤波器
    lpdf = [-0.0544153492, 0.3125, 0.6875, -0.1875];
    hpdf = [-0.1875, -0.6875, 0.3125, 0.0544153492];

    Fh = lpdf' * hpdf;
    Fv = hpdf' * lpdf;
    Fd = hpdf' * hpdf;

    % ===================== 工具箱函数 imfilter =====================
    R_h = imfilter(img, Fh, 'symmetric');
    R_v = imfilter(img, Fv, 'symmetric');
    R_d = imfilter(img, Fd, 'symmetric');

    % 代价
    rho = abs(R_h) + abs(R_v) + abs(R_d);
    
    % ===================== 工具箱函数 imresize =====================
    rho = imresize(rho, size(coef)); 
end