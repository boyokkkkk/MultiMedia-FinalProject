function I_coef = adjust_coefficients(O, S, qt_o, qt_c)
    [h, w] = size(O);
    I_coef = O;
    for i = 1:h
        for j = 1:w
	    % 定位 8×8 块内位置，获取当前系数的量化步长
            mo = qt_o(mod(i-1,8)+1, mod(j-1,8)+1);
            mc = qt_c(mod(i-1,8)+1, mod(j-1,8)+1);
      
            I_coef(i,j) = round(S(i,j)*mc/mo);
        end
    end
end