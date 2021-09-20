function [sep_exps_days,sep_exps_sess,sep_exps_days_health,sep_nms,censored_wells_any_separated,sep_well_locations,...
    dosage_names_full,strain_names_full,sep_activities_full] = ...
    separate_divisions(data_storage,censored_wells_any,...
    potential_lifespans_days,potential_lifespans_sess,potential_healthspans_days,worm_daily_activity)

sep_activities_full = [];

for i = 1:length(data_storage)
    divisions_full{i} = readcell([data_storage{i} 'divisions.csv']);
end

dosage_names_full = string();
strain_names_full = string();

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
            
%             separate_exps_per_plate(i) = sep_exps_counter;
            separate_exps_per_plate(i) = sum(~cellfun(@isempty,sep_well_locations));
            
            if i > 1
                separate_exps_per_plate(i) = (separate_exps_per_plate(i)-sum(separate_exps_per_plate(1:i-1)));
            end
            
            if ~isempty(sep_well_locations{1,o})
                sep_exps_counter = sep_exps_counter+1;
            end
            o = o+1;

            
        end
    end
    
    dosage_names_full = [dosage_names_full; dosage_names];
    strain_names_full = [strain_names_full; strain_names];
    
    if isequal(i,1)
        dosage_names_full(1) = [];
        strain_names_full(1) = [];
    end
end

dosage_names_full = cellstr(unique(dosage_names_full));
strain_names_full = cellstr(unique(strain_names_full));


good_idx = ones(size(sep_well_locations));
for i = 1:length(sep_well_locations)
    
    if isempty(sep_well_locations{i})
        good_idx(i) = 0;
    end
    
end

good_idx_num = nonzeros( (1:length(good_idx)).*(good_idx));

sep_well_locations = sep_well_locations(good_idx_num);
sep_nms = sep_nms(good_idx_num);

k = 1;
for i = 1:length(divisions_full)
    for j = 1:separate_exps_per_plate(i)
        sep_exps_days{1,k} = potential_lifespans_days{i}(sep_well_locations{1,k});
        sep_exps_sess{1,k} = potential_lifespans_sess{i}(sep_well_locations{1,k});
        sep_exps_days_health{1,k} = potential_healthspans_days{i}(sep_well_locations{1,k});
        censored_wells_any_separated{1,k} = censored_wells_any{i}(sep_well_locations{1,k});
        
        temp_activities = worm_daily_activity{i}(sep_well_locations{1,k});
        this_exp_max_activity = max(cellfun(@max,temp_activities));
        
        for m = 1:length(temp_activities)
            temp_activities{m} = temp_activities{m}/this_exp_max_activity;
        end
        
        sep_activities_full{1,k} = temp_activities;
        k=k+1;
    end
end

disp('end')

end