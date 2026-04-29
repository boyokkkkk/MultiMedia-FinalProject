function I_coef = adjust_coefficients(O, S, qt_o, qt_c)
% adjust_coefficients - Coefficient adjustment for robust JPEG steganography
%
% Goal: construct I (in qt_o domain) such that after channel re-compression
% at quality Qc, the resulting DCT coefficients equal S exactly.
%
% Channel compression formula:
%   out = round( dequant(I, qt_o) / qt_c )
%       = round( I * qt_o / qt_c )
%
% We need: round( I * qt_o / qt_c ) = S
% Solution: I = round( S * qt_c / qt_o )
%   Proof: round( round(S*qt_c/qt_o) * qt_o/qt_c )
%        = round( S * qt_c/qt_o * qt_o/qt_c + eps )
%        = round( S + eps ) = S  (S is integer, eps < 0.5 when qt_c <= qt_o)
%
% Inputs:
%   O    - original cover DCT coefficients (at quality Qo, unused but kept for API)
%   S    - stego DCT coefficients (embedded at channel quality Qc)
%   qt_o - 8x8 quantization table for Qo
%   qt_c - 8x8 quantization table for Qc
%
% Output:
%   I_coef - adjusted intermediate DCT coefficients (in qt_o domain)

    [H, W] = size(S);

    % Build full-size quantization step maps by tiling the 8x8 tables
    num_blocks_h = ceil(H / 8);
    num_blocks_w = ceil(W / 8);
    MO = repmat(qt_o, num_blocks_h, num_blocks_w);
    MC = repmat(qt_c, num_blocks_h, num_blocks_w);
    MO = MO(1:H, 1:W);
    MC = MC(1:H, 1:W);

    % I = round(S * qt_c / qt_o)
    % This ensures round(I * qt_o / qt_c) = S
    I_coef = round(double(S) .* MC ./ MO);
end
