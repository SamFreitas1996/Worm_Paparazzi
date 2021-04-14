



incomplete_data_censor = cell(1,100);

parfor i = 1:100
    
    
    for j = 1:240
        
        temp_rand = rand(1)
        
        temp_idx = zeros(1,240);
        
        if temp_rand>0.6
            temp_idx(i) = 1;
        end
        
    end
    
    incomplete_data_censor{i} = temp_idx;
    
end

incomplete_data_censor_full = zeros(1,240);
for i = 1:length(incomplete_data_censor)
    
    incomplete_data_censor_full = incomplete_data_censor_full + incomplete_data_censor{i};
    
end

incomplete_data_censor_full = double(incomplete_data_censor_full>0);




