function [sep_exps_days,sep_exps_sess,sep_exps_days_health,sep_nms,censored_wells_any_separated,sep_well_locations] = ...
    separate_divisions(data_storage,censored_wells_any,potential_lifespans_days,potential_lifespans_sess,potential_healthspans_days)

for i = 1:length(data_storage)
    divisions_full{i} = readcell([data_storage{i} 'divisions.csv']);
end

o=1;
separate_exps_per_plate = zeros(1,length(data_storage));
for i = 1:length(divisions_full)
    
    sep_exps_counter = 1;
    
    dosage_isolation = string(divisions_full{i}(2:end,2));
    strain_isolation = string(divisions_full{i}(2:end,3));
    
    dosage_names = unique(dosage_isolation);
    strain_names = unique(strain_isolation);
    
    for j = 1:length(dosage_names)
        for k = 1:length(strain_names)
            dos_temp = zeros(size(dosage_isolation));
            str_temp = zeros(size(strain_isolation));
            dos_temp(dosage_isolation==dosage_names{j}) = 1;
            str_temp(strain_isolation==strain_names{k}) = 1;
            
            sep_well_locations{1,o} = nonzeros((1:240)'.*str_temp.*dos_temp);
                        
            sep_nms{1,o} = [char(dosage_names(j)) ' - ' char(strain_names(k))];
            
            separate_exps_per_plate(i) = sep_exps_counter;
            
            o = o+1;
            
            sep_exps_counter = sep_exps_counter+1;
            
        end
    end
end

k = 1;
for i = 1:length(divisions_full)
    for j = 1:separate_exps_per_plate(i)
        sep_exps_days{1,k} = potential_lifespans_days{i}(sep_well_locations{1,k});
        sep_exps_sess{1,k} = potential_lifespans_sess{i}(sep_well_locations{1,k});
        sep_exps_days_health{1,k} = potential_healthspans_days{i}(sep_well_locations{1,k});
        censored_wells_any_separated{1,k} = censored_wells_any{i}(sep_well_locations{1,k});
        k=k+1;
    end
end

disp('end')

end