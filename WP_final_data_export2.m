function WP_final_data_export2(exp_nm,data_storage,potential_lifespans_days,potential_healthspans_days,...
    censored_wells_manual,censored_wells_runoff_nn,censored_wells_runoff_var,worms_not_dead,...
    final_data_export_path,full_exp_name,any_nn_activity,censored_wells2,worm_daily_activity,worm_unresponsive_to_stimulus)

% create header
myHeader = ...
    ["Worm number",...
    "Plate ID",...
    "Well Location",...
    "Dosage",...
    "Strain",...
    "Any worm detected",...
    "Last day of observation",...
    "Last day of health",...
    "Manual Censor",...
    "Runoff Censor inital",...
    "Runoff Censor experiment",...
    "Potentially still alive",...
    "Death Detected"...
    "Incomplete Data",...
    "Unresponsive to stimulus"];

% create export cell array
export_csv = cell(length(censored_wells_manual)*length(censored_wells_manual{1}),length(myHeader));

% import plate ID and worm_number 
k = 1;
worm_number = 1;
for i = 1:length(exp_nm)
    for j = 1:length(censored_wells_manual{i})
        export_csv{k,1} = worm_number;
        export_csv{k,2} = exp_nm{i};
        k=k+1;
        worm_number = worm_number +1;
    end
end

% load in location,dosage,and strain data
for i = 1:length(data_storage)
    divisions_full{i} = readcell([data_storage{i} 'divisions.csv']);
end

% import location,dosage,and strain data
for i = 1:length(divisions_full)
    this_div = divisions_full{i}(2:end,:);
    export_csv( 1 + 240*(i-1) : 240*i,3:5) = this_div;
end

% determine if worm is dead
for i = 1:length(censored_wells_manual)
    death_detected{i} = double(~(censored_wells_manual{i}|censored_wells_runoff_nn{i}|censored_wells_runoff_var{i}|worms_not_dead{i}));
end

% import lifespan, healthspan, censor manual, inital runoff, experimental
% runoff, still alive, and death
for i = 1:length(potential_lifespans_days)
    
    for j = 1:length(potential_lifespans_days{1})
        export_csv(((240*(i-1)))+j,6) = {any_nn_activity{i}(j)};
        export_csv(((240*(i-1)))+j,7) = {potential_lifespans_days{i}(j)};
        export_csv(((240*(i-1)))+j,8) = {potential_healthspans_days{i}(j)};
        export_csv(((240*(i-1)))+j,9) = {censored_wells_manual{i}(j)};
        export_csv(((240*(i-1)))+j,10) = {censored_wells_runoff_nn{i}(j)};
        export_csv(((240*(i-1)))+j,11) = {censored_wells_runoff_var{i}(j)};
        export_csv(((240*(i-1)))+j,12) = {worms_not_dead{i}(j)};
        export_csv(((240*(i-1)))+j,13) = {death_detected{i}(j)};
        export_csv(((240*(i-1)))+j,14) = {censored_wells2{i}(j)};
        export_csv(((240*(i-1)))+j,15) = {worm_unresponsive_to_stimulus{i}(j)};
    end
    
end


T = cell2table(export_csv,'VariableNames',myHeader);

daily_activity = daily_activity_to_array(worm_daily_activity);

T2 = array2table(daily_activity);

final_table = [T T2];

writetable(final_table,fullfile(final_data_export_path,full_exp_name,[full_exp_name '.csv']))

disp(['Exported to: ' fullfile(final_data_export_path,full_exp_name)])

disp('end');



end