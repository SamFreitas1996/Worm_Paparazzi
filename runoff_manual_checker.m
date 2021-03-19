% runoff image generator 



function runoff_manual_checker(data_storage,thisWorm_data,thisWorm_ROI_num,thisMoveVar,pot_death)

% load in the processed data
procc_dir = dir(fullfile([data_storage '/processed_data'],'*.png'));
[~,sort_idx,~] = natsort({procc_dir.name});
procc_dir = procc_dir(sort_idx);
procc_dir(ismember( {procc_dir.name}, {'.', '..'})) = [];

this_procc = cell(1,3);
for i = pot_death-1:pot_death+1
    this_procc{i} = imread(fullfile(procc_dir(1).folder,procc_dir(i).name));
end

% load in the ROI
ROI2_dir = dir(fullfile([data_storage '/raw_data'],'*.mat'));
[~,sort_idx,~] = natsort({ROI2_dir.name});
ROI2_dir = ROI2_dir(sort_idx);
ROI2_dir(ismember( {ROI2_dir.name}, {'.', '..','newROIs.mat','peaks.mat','sess_reg_idx.mat','censor.mat','nth_sess_activity.mat'})) = [];  %remove . and ..

newROIs2= cell(1,3);
for i = pot_death-1:pot_death+1
    a = load([ROI2_dir(i).folder '/' ROI2_dir(i).name],'thisROI');
    newROIs2{i} = a.thisROI;
    newROIs2{i} = (newROIs2{i} ==thisWorm_ROI_num);
end




end