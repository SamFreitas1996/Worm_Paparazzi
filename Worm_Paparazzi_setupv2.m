% Worm Paparazzi setup


% set up the variables that you want constant for all the experiments 
% this code outlines each script and dependency necessary for running
% [fList1,pList1] = matlab.codetools.requiredFilesAndProducts([pwd '/Worm_paparazzi_setupv2.m']);

warning('off', 'MATLAB:MKDIR:DirectoryExists');
% clc
clear all
close all force hidden 
% % % % gpuDevice(1);
% turns off the warning that says a directory (folder) already exists, is
% rather annoying when looping, keep off
% clears everything in the current matlab 
% and resets the allocated GPU memory 

%%%%%% Mandatory
% These are the variables that must be set up before runing ANY experiment

use_last_experiment_setup = 0;
% use the last experiment run again

make_new_censors_and_divisions = 0;
% this will create a new manual censors and divisions that the user specifies
% 1 - normal make a unique censor 
% 0 - testing, use previous censor 
% if no censor exists or can be found a new one must be made

compute_new_zstack_data = 1;
% this will create new zstack data that will be used for the final data
% analysis, turning this off will just load the previously created data and
% skip the creation step - should only be used for testing
% 1 - normal, create new data
% 0 - testing, just run data analysis and skip data creation

skip_data_processing = 0;
% this will skip the WP_analysis step and go straight to the death
% calculations and runoff predictions THIS WILL NOT SAVE .MAT IN _DATA
% 0 - normal, keep analysis on
% 1 - testing, skip the analysis step (speeds up testing)

skip_nn_runoff = 0;
% skip the neural network runoff in case it was already done
% 1 - skip
% 0 - process - default

ignore_badly_registered_sessions = 0;
% sometimes there are badly registered sessions that need to be skipped
% if the censor for this is wrong then you can skip it
% 99% of the time the censor is correct, but somtimes high activity worms
% in thick bacteria can trigger this, or plates without FUDR
% 0 - censor badly registerd session - default
% 1 - do not use censor 

reduce_final_noise = 1;
% this uses the completed zstacks to get rid of a most of the extra noise
% 1 - attempt to remove noise
% 0 - do not remove noise and use raw zstacks 

save_data = 1;
% This will determine if the system saves the data files that it creates 
% very very very important, if any data wants to be calculated, then keep
% on 1
% 1 - save data
% 0 - do not save data (for testing purposes only)

bw_analysis = 1;
% use the binary classification of the zstack images 
% give a less variable source of data
% 1 - use bw
% 0 - use the inegrated grayscale

normalize_intensities = 1;
% takes the varability of the input images and normalizes their intensities
% to themselves on a per session basis 

sess_activity_buffer=1;
% each session represents 8 hours
% If a worm is not responsive for 3 sessions of exposure totalling 24 hours
% then its probably dead
% the noise needs to be figured out though

export_data = 1;
% all 'potential_lifespans' are saved as a .mat file regardless
% but if you want to export this as a .csv file then it will do this 
% 1 - export as .csv and as .mat
% 0 - just export as a .mat

final_data_export_path = '/groups/sutphin/_Data';

start_sess = 1;
% Specifies what day the zstacks sould start being created on
% useful if continuing an experimnt
% 1 - start on day 1 (default)
% other - start on selected day

min_activity = 750;
% depreciated when using BW analysis 
% this value is only necessary if bw_analysis = 0
% minimun activity that needs to be present to threshold as a movement
% lower is more sensitive 
% higher reduces noise more
% 500 - normal

runoff_cutoff = 0;
% depreciated runoff measurement
% session to determine if a worm is present in the well
% this is a scalar from session 1 to the number of sessions
% if 0 is chosen then the max activity of all the worms will be used
% 0 - max activity
% # - specific chosen session
% as it currently stands the runoff cutoff if set to 0 will set the cutoff
% (still not used but saved) to the index of the max activity session

num_pics_per_session = 25;
% this variable is depreciated, but a good reminder to make sure the amount
% of images is constant between every system

num_divisions_per_plate = 2;
% if there are multiple divisions on the same plate (ex: gls130 and N2)
% then this will automatically separate the plates into different
% specifications after exporting from the WP_function
% 1 - each plate is a single experiemtn 
% 2 - each plate is divided in half (1:2)
% 4 - each plate is divided into quarters   (1:3)
%                                           (2:4)

ROI_refrence_path = [pwd '/ROI_mini.mat'];
% this should be the same path that was used in WPdata, this points towards
% the previous "base" ROIs

amount_of_smoothing = 0.3;
% This is for the post-processing step that takes very noisy image data
% that has been resolved to a single data point and finds the most
% approximate 'smoothed' curve, the higher the number the larger the amount
% of data thrown away is, generally 0.3 to 0.25 is standard
% depreciated variable no longer used

show_intermediate_data = 0;
% this will create many figures that show the specific data files that are
% being created from the program dynamically as they are being created.
% This is not necessary as all images are saved to disk regardless, but can
% be useful if wanted
% 0 - do not show intermediate images
% 1 - show intermediate images (will consume ram)

dont_align_images = 0;
% This is really the only variable that would need to be changed 
% selecting 1 will not align the images, and create a significantly LESS
% accurate 'stack', while selecting 0 will register (align) every image as
% best as possble and create a much MORE accurate system
% selecting 1 should only really occur when data fidelity is not required
% and only a test section is being processed, keep on 0
% 0 - align images (slow and accurate)
% 1 - no alignment (fast and inaccurate)

save_aligned_images = 0;
% this will generate a huge amount of data
% this saves the aligned images into a new folder 
% ex: N2_stab8 (normal)
%     N2_stab8-data (normal)
%     N2_stab8-registrations (new)

save_only_few = 1;
% saves only the first, middle, and last sessions 
% highly recommended 
% does not do anything if save_aligned_images = 0

% These are the registration variables that need to be set up before any of
% the 'ecc' registrations happen, these are so far pretty consistant, and
% should onyl e changed if the user understands image processing
NoI = [100,3,3,3]; % number of iterations for each registration
NoL = 6;  % number of pyramid-levels
transform = 'affine'; % type of image transform 
init=[eye(2) 20*ones(2,1)]; %translation/affine-only initialization
se=strel('disk',40,4);

% Find which experiment(s) the user wants to run
% make sure you select the actual images folder, not the data folder
if use_last_experiment_setup
    disp('using the last setup experiment');
else
    exp_dir_path = uigetdir2('/groups/sutphin/');
    
    if isempty(exp_dir_path)
        error('No experiment selected')
    end
    
end

% find number of plates and experiments total
number_of_plates = length(exp_dir_path);
% number_of_experiments = number_of_plates*num_divisions_per_plate;

% get the user definition for the input names for each experiment and the
% overarching experiment name 
% [names_of_divisions,full_exp_name] = user_input_division_names(exp_dir_path,num_divisions_per_plate,number_of_experiments);

if ~use_last_experiment_setup
    full_exp_name = inputdlg('What is the full experiment name? Please no spaces');
    full_exp_name = full_exp_name{1};
end

%%% set up variables 
exp_nm                      = cell(1,number_of_plates);
exp_fol                     = cell(1,number_of_plates);
exp_dir                     = cell(1,number_of_plates);
num_days                    = cell(1,number_of_plates);
sess_nums                   = cell(1,number_of_plates);
data_storage                = cell(1,number_of_plates);
zstacks_paths               = cell(1,number_of_plates);
censored_wells_manual       = cell(1,number_of_plates);
censored_wells2             = cell(1,number_of_plates);
censored_wells_runoff_nn    = cell(1,number_of_plates);
censored_wells_runoff_var   = cell(1,number_of_plates);
raw_sess_data_aft           = cell(1,number_of_plates); 
raw_sess_data_bef           = cell(1,number_of_plates);
raw_sess_data_integral      = cell(1,number_of_plates);
potential_lifespans_sess    = cell(1,number_of_plates); 
potential_lifespans_days    = cell(1,number_of_plates);


% steps for processing 

% Create data storage
% Create censors and divisons
% Create Zstack data
% Analyze data sets
% Interpolate runoff and death calculations
% export data

% create data storage, experiment names, experiment folders, and other
% setup data
for i = 1:number_of_plates
    
    this_exp_dir_path = exp_dir_path{i};
    
    this_exp_dir = dir(this_exp_dir_path);
    this_exp_dir(ismember( {this_exp_dir.name}, {'.', '..','raw_data','raw_data.mat','.DS_Store'})) = [];  %remove . and ..
    
    exp_dir{i} = this_exp_dir;
    
    % Determines the data storage
    [exp_fol{i},exp_nm{i},~]=fileparts(this_exp_dir_path);
    data_storage{i} = [exp_fol{i} '/' exp_nm{i} '-data/'];
    
end


% Create the first manual censor, and well divisions
% Isolates each well into its proper divisions and creates the first censor
% for looking at "strange" wells 

for i = 1:number_of_plates
    
    disp(['Loading censor and division data for ' exp_nm{i} '--- this might take a couple minutes'])
    
    % If it is necessary to create new setup data
    if make_new_censors_and_divisions
        
        % this loads in the ROI data for the division and manual censor classification
        load([data_storage{i} 'raw_data/newROIs.mat']);
        
        % create divisions interactive 
        experiment_divisions_manual2(exp_dir{i},newROIs,data_storage{i},exp_nm{i},...
            final_data_export_path,full_exp_name)
        
        % create censors interactive
        censored_wells_manual = censor_wells_manual(exp_dir{i},newROIs);
        save(char([data_storage{i} 'raw_data/censor']),'censored_wells_manual');
        temp_cen_wells_for_saving{i}=censored_wells_manual;
    
    % otherwise try and load the censors that were previously made
    else
        try 
            tempCen = load(char([data_storage{i} 'raw_data/censor.mat']));
%             index = (cellfun(@isempty, tempCen.censored_wells) == 0);
%             tempCen = tempCen.censored_wells(index);
            tempCen = tempCen.censored_wells_manual;
            try 
                tempCen2 = tempCen{i};
            catch
                tempCen2 = tempCen;
            end
            
            censored_wells_manual{i} = tempCen2;
        catch
            load([data_storage{i} 'raw_data/newROIs.mat']);
            censored_wells_manual{i} = censor_wells_manual(exp_dir{i},newROIs);
            save(char([data_storage{i} 'raw_data/censor']),'censored_wells_manual');
        end
        
    end
    
end
if make_new_censors_and_divisions
    censored_wells_manual = temp_cen_wells_for_saving;
end
clear newROIs tempCen temp_cen_wells_for_saving_badly

% create zstack raw data information and other post processing tools 
for i = 1:number_of_plates
    
    this_exp_dir_path = exp_dir_path{i};
    
    calculate_optical_flow = 0;
    
    [zstacks_paths{i},sess_nums{i},num_days{i}] = ...
        WP_create_zstacks_testing(...
        this_exp_dir_path, dont_align_images,...
        save_data,compute_new_zstack_data,...
        normalize_intensities,start_sess,...
        calculate_optical_flow,...
        save_aligned_images,save_only_few,NoI,NoL,transform,init);

end

% analyze raw data sets and calculate the first lifespan pass
for i = 1:number_of_plates
    
    if ~skip_data_processing
        
        [raw_sess_data_aft{i}, raw_sess_data_bef{i}, ...
            raw_sess_data_integral{i},censored_wells2{i},runoff_cutoff2{i},...
            raw_sess_data_aft_bw{i},raw_sess_data_bef_bw{i}] = ...
            WP_analyze_data(...
            data_storage{i},reduce_final_noise,runoff_cutoff,censored_wells_manual{i},bw_analysis,final_data_export_path,full_exp_name);
        
    else
        [raw_sess_data_aft{i}, raw_sess_data_bef{i}, ...
            raw_sess_data_integral{i},censored_wells2{i},runoff_cutoff2{i},...
            raw_sess_data_aft_bw{i},raw_sess_data_bef_bw{i}] = ...
            WP_dont_analyze_data(data_storage{i},final_data_export_path,full_exp_name,runoff_cutoff);
        
    end
    
    [potential_lifespans_days{i}, potential_lifespans_sess{i},worms_not_dead{i},data_points_to_omit{i},worm_daily_activity{i}] = ...
        WP_calculate_death_daily...
        (raw_sess_data_aft{i}, raw_sess_data_bef{i}, ...
        raw_sess_data_integral{i},censored_wells_manual{i},...
        raw_sess_data_aft_bw{i},raw_sess_data_bef_bw{i},...
        export_data,i,runoff_cutoff2{i},data_storage{i},...
        min_activity,sess_activity_buffer,sess_nums{i},...
        exp_nm{i},num_days{i},bw_analysis,ignore_badly_registered_sessions,...
        final_data_export_path,full_exp_name);

end


% Runoff and death calculations 
for i = 1:number_of_plates
    
    [censored_wells_runoff_var{i},censored_wells_runoff_nn{i},potential_healthspans_days{i},any_nn_activity{i}] = ...
        WP_runoff_nn_daily...
        (data_storage{i},exp_nm{i},censored_wells_manual{i},sess_nums{i},skip_nn_runoff,final_data_export_path,full_exp_name);
    
    [potential_lifespans_days{i}, potential_lifespans_sess{i},worms_not_dead{i},potential_healthspans_days{i},worm_unresponsive_to_stimulus{i}] = ...
        WP_recalculate_death_daily...
        (data_storage{i},exp_nm{i},sess_nums{i},final_data_export_path,full_exp_name,worms_not_dead{i},data_points_to_omit{i});
    
    temp_cen = (censored_wells_runoff_var{i}|censored_wells_runoff_nn{i});
    
    WP_export_whole_plate_data_daily(export_data,temp_cen,data_storage{i},...
        exp_nm{i},i,sess_nums{i},num_days{i},final_data_export_path,full_exp_name,data_points_to_omit{i})
    
end

for i = 1:length(censored_wells_runoff_nn)
    censored_wells_any{i} = (censored_wells_manual{i}|censored_wells_runoff_nn{i}|...
        censored_wells_runoff_var{i}|censored_wells2{i});
end

group_similar_data = 1;
use_ecdf = 1;
add_control_to_everything = 1;
%Empirical cumulative distribution function

plot_WP_data(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days,final_data_export_path,...
    full_exp_name,sess_nums,group_similar_data,use_ecdf,add_control_to_everything,worm_daily_activity)

plot_activity_WP_data(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days,final_data_export_path,...
    full_exp_name,sess_nums,group_similar_data,use_ecdf,add_control_to_everything,worm_daily_activity)

close all

% export final to csv
WP_final_data_export2(exp_nm,data_storage,potential_lifespans_days,potential_healthspans_days,...
    censored_wells_manual,censored_wells_runoff_nn,censored_wells_runoff_var,worms_not_dead,...
    final_data_export_path,full_exp_name,any_nn_activity,censored_wells2,worm_daily_activity,worm_unresponsive_to_stimulus)















