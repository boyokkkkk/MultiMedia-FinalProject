function rho = get_juniward_cost(cover_jpg)
    % J-Uniward 方向残差代价计算（完整版，无工具箱依赖）
    % 支持灰度图，自动处理维度，不报错

    % 1. 读取 JPEG
    jpg = jpeg_read(cover_jpg);
    coef = jpg.coef_arrays{1};
    img = imread(cover_jpg);
    
    % 自动转灰度（解决 3 通道错误！）
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    img = double(img);

    % ========================
    % J-Uniward 方向滤波器
    % ========================
    lpdf = [-0.0544153492, 0.3125, 0.6875, -0.1875];
    hpdf = [-0.1875, -0.6875, 0.3125, 0.0544153492];

    Fh = lpdf' * hpdf;
    Fv = hpdf' * lpdf;
    Fd = hpdf' * hpdf;

    % ========================
    % 手写滤波（无 imfilter）
    % ========================
    R_h = my_conv2(img, Fh);
    R_v = my_conv2(img, Fv);
    R_d = my_conv2(img, Fd);

    % 代价图
    rho = abs(R_h) + abs(R_v) + abs(R_d);
    rho = imresize_mat(R_h, size(coef)); 
end

% 手写卷积 2D（完全不依赖工具箱）
function out = my_conv2(img, kernel)
    [h, w] = size(img);
    [kh, kw] = size(kernel);
    ph = floor(kh/2);
    pw = floor(kw/2);

    out = zeros(h, w);
    for i = ph+1 : h-ph
        for j = pw+1 : w-pw
            block = img(i-ph:i+ph, j-pw:j+pw);
            val = 0;
            for a = 1:kh
                for b = 1:kw
                    val = val + block(a,b) * kernel(a,b);
                end
            end
            out(i,j) = val;
        end
    end
end

% 简单缩放（兼容所有尺寸）
function out = imresize_mat(img, sz)
    out = zeros(sz(1), sz(2));
    h = min(size(img,1), sz(1));
    w = min(size(img,2), sz(2));
    out(1:h, 1:w) = img(1:h, 1:w);
end