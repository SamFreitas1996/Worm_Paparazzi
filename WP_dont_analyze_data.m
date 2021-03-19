function [raw_sess_data_aft, raw_sess_data_bef, raw_sess_data_integral,censored_wells2,runoff_cutoff2,raw_sess_data_aft_bw,raw_sess_data_bef_bw] = ...
    WP_dont_analyze_data(data_storage,final_data_export_path,full_exp_name,runoff_cutoff) 

censored_wells2 = zeros(1,240);
try
data_temp = load(fullfile(data_storage,'processed_data','norm_activity'));
raw_sess_data_aft = data_temp.raw_sess_data_aft;
raw_sess_data_bef = data_temp.raw_sess_data_bef;
raw_sess_data_integral = data_temp.raw_sess_data_integral;
runoff_cutoff2 = runoff_cutoff;
raw_sess_data_aft_bw = data_temp.raw_sess_data_aft_bw;
raw_sess_data_bef_bw = data_temp.raw_sess_data_bef_bw;
catch
    data_temp = load(fullfile(data_storage,'processed_data','proc_zstacks','zstacks.mat'));
    raw_sess_data_aft = data_temp.raw_sess_data_aft;
    raw_sess_data_bef = data_temp.raw_sess_data_bef;
    raw_sess_data_integral = data_temp.raw_sess_data_integral;
    runoff_cutoff2 = runoff_cutoff;
    raw_sess_data_aft_bw = data_temp.raw_sess_data_aft_bw;
    raw_sess_data_bef_bw = data_temp.raw_sess_data_bef_bw;
end

save(char([data_storage 'processed_data/proc_zstacks/zstacks.mat']),...
    'raw_sess_data_aft', 'raw_sess_data_bef', 'raw_sess_data_integral','censored_wells2','runoff_cutoff2',...
    'raw_sess_data_aft_bw','raw_sess_data_bef_bw')
[~,exp_nm,~]=fileparts(data_storage(1:length(data_storage)-1));
mkdir(fullfile(final_data_export_path,full_exp_name))
f_out = fullfile(final_data_export_path,full_exp_name,[exp_nm '.mat']);
save(char(f_out),...
    'raw_sess_data_aft', 'raw_sess_data_bef', 'raw_sess_data_integral','censored_wells2','runoff_cutoff2',...
    'raw_sess_data_aft_bw','raw_sess_data_bef_bw')




end