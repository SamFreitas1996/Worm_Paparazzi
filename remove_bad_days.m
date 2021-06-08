function good_idx = remove_bad_days(sep_exps_days)

k=1;
for i = 1:length(sep_exps_days)
    
    if sep_exps_days(i) > 1
        good_idx(k) = i;
        k=k+1;
    end
end


end