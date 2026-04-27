function ber = embed_extract(cover_jpg, rho, payload, Qc)
    jpg = jpeg_read(cover_jpg);
    cover_coef = jpg.coef_arrays{1};
    
    nbits = round(nnz(cover_coef) * payload);
    msg = randi([0 1], nbits, 1);
    
    stego_coef = stc_embed(cover_coef, rho, msg, payload);
    jpg.coef_arrays{1} = stego_coef;
    jpeg_write(jpg, 'result/stego_temp.jpg');
    
    Ist = imread('result/stego_temp.jpg');
    imwrite(Ist, 'result/recompress.jpg', 'Quality', Qc);
    
    jpg2 = jpeg_read('result/recompress.jpg');
    recoef = jpg2.coef_arrays{1};
    
    msg_ext = stc_extract(recoef, cover_coef, rho, payload);
    ber = sum(xor(msg, msg_ext)) / length(msg_ext);
end