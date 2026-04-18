function ber_score = calculate_ber(original_bits, extracted_bits)
    min_len = min(length(original_bits), length(extracted_bits));
    err_count = sum(original_bits(1:min_len) ~= extracted_bits(1:min_len));
    ber_score = err_count / min_len;
end