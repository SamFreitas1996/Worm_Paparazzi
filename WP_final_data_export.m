function WP_final_data_export(sep_exps_days, sep_exps_sess, sep_nms, ...
    censored_wells_manual,censored_wells_runoff_nn,censored_wells_runoff_var,...
    final_data_export_path,full_exp_name,names_of_divisions,exp_nm,worms_not_dead,sep_well_locations)
%%%%%doesnt works 
myHeader = ["Worm number","Plate ID","Group ID","Well Location","Last day of observation","Last session of observation","Manual Censor","Runoff Censor Variance","Runoff Censor Network","Potentially still alive","Death Detected"];

% [div,exps] = size(potential_lifespans_days_separated);

for i = 1:length(censored_wells_manual)
    death_detected{i} = double(~(censored_wells_manual{i}|censored_wells_runoff_nn{i}|censored_wells_runoff_var{i}|worms_not_dead{i}));
end

export_csv = cell((length(exp_nm)*240)+1, length(myHeader));
for i = 1:length(sep_nms)
    num_worms_per_group(i) = length(sep_exps_days{i});
end
for i = 1:length(censored_wells_manual)
    num_worms_per_plate(i) = length(censored_wells_manual{i});
end
mkdir(fullfile(final_data_export_path,full_exp_name))

% make header
for i = 1:length(myHeader)
    export_csv{1,i} = myHeader(i);
end

% make worm numbers
for i = 1:sum(num_worms_per_plate)
    export_csv{i+1,1} = i;
end

% make Plate ID and well location
for i = 1:length(exp_nm)
    for j = 1:num_worms_per_plate(i)
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),2} = string(exp_nm{i});
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),4} = j;
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),7} = censored_wells_manual{i}(j);
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),8} = censored_wells_runoff_var{i}(j);
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),9} = double(censored_wells_runoff_nn{i}(j));
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),10} = worms_not_dead{i}(j);
        export_csv{(1 + j + (i-1)*(num_worms_per_plate(i))),11} = death_detected{i}(j);
    end
end

% make group ID
for i = 1:length(sep_nms)
    for j = 1:num_worms_per_group(i)
        export_csv{(1 + j + (i-1)*(num_worms_per_group(i))),3} = string(sep_nms{i});
    end
end

% make last day of observation 
k = 2;
for i = 1:length(sep_exps_days)
    for j = 1:num_worms_per_group(i)
        export_csv{k,3} = string(sep_nms{i});
        export_csv{k,5} = sep_exps_days{i}(j);
        export_csv{k,6} = sep_exps_sess{i}(j);
        k=k+1;
    end
end

T = cell2table(export_csv(2:end,:),'VariableNames',myHeader);
writetable(T,fullfile(final_data_export_path,full_exp_name,[full_exp_name '.csv']))

end