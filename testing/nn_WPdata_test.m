% WP ROIs and data setupsq

% Worm Paparazzi data setup and preprocessing
% Creates custom per-basis ROIs for each movement sessions
% developed by Samuel Freitas
% December 2019
% Sutphin Lab - University of Arizona - 2019
% must have a CUDA enabled GPU installed
% [fList2,pList2] = matlab.codetools.requiredFilesAndProducts([pwd '/nn_WPdata_test.m']);

warning('off', 'MATLAB:MKDIR:DirectoryExists');
% turns off the warning that says a directory (folder) already exists, is
% rather annoying when looping
warning('off','all')
% turns off all unspecific warnings, this is deliberate as warnings are
% used in the program for calculations, it just cleans up the command
% window
%gpuDevice(1);
clear all

tic
%%%%%% Mandatory
% These are the variables that must be set up before runing ANY experiment

start_from_scratch = 1;
% Detections for each day
% where and when specific details from each session
% unless running the same exact experiment, keep on 1

create_custom_ROIs = 1;

% This will create a custom basis ROI(s) for the experiment
% generally this should be kept at 1 unless re-running an experiment that
% already has the ROI's created

show_plots_peaks = 0;
% very specific for showing ALL the plots for determinations of how many
% sessions are found in each day, 99% of the time keep show_plots_peaks = 0;

show_progress_images = 0;
% will continuously show progress images
% keep on 0 unless create_custom_ROIs = 0, then switch to 1 for babysitting

% ROI_images_storage = "E:/Codes/ROI_zoom_lens.mat";
ROI_images_storage = [pwd '/images_for_ROI'];
% this folder contains the images that will be automatically processed by
% the code, do not worry if there is already pictures in the folder, or is
% there are no pictures in this folder,
% if the folder does not exist it will be made at this directory

ROI_refrence_path = [pwd '/ROI_mini.mat'];
% ROI_refrence_path = "//fs.mcb.arizona.edu/LabSupport/Sutphin Lab/Users/Sam Freitas/ROI_mini.mat";
% this is the previous ROIs that will be used in the calculations for
% finding the best ROI for any situation
% it must be a .mat file that was previously created

% create_custom_ROIs_path = "Z:/Sutphin Lab/Projects/Worm Lifespan Robot/WormWatcher/WWAnalyzer/Matlab source/createROIsCompound.m";
create_custom_ROIs_path = [pwd '/createROIsCompound.m'];
% this program uses the customROI algorithm created by the Feng lab out of
% penn, this path must point to the createROIsCompound.m file (usually in
% 'MatLab source')

overwrite_bad_images = 1;
% sometimes things get corrupted for no reason
% leave this to fix that

%%%%%%% Have the user select which experiment they want

% the user must choose which experiment to process
% when choosing which experiment, it must be the folder that contains the
% individual days, which contains the pictures
%%%%%%% IT IS much much faster if files are on a local SSD (preferably a m.2 ;)
% % this_experiment_folder = uigetdir('/groups/sutphin/', "select folder with the indivudual days");
exp_dir_path = uigetdir2('/groups/sutphin/');

for o = 1:length(exp_dir_path)
    
    this_experiment_folder = exp_dir_path{o};
    
    if sum(this_experiment_folder=='.')
        disp('There was a period detected in the file name, renaming to _');
        experiment_folder_new = strrep(this_experiment_folder,'.','_');
        movefile(this_experiment_folder,experiment_folder_new);
        this_experiment_folder = experiment_folder_new;
    end
    [exp_fol,exp_nm,~]=fileparts(this_experiment_folder);
    data_storage = [exp_fol '/' exp_nm '-data/'];
    disp(['Creating unique ROIs for experiment: ' exp_nm])
    
    mkdir(fullfile(pwd,'temp_imgs'))
    % example
    % experiment_folder='//fs.mcb.arizona.edu/labsupport/Sutphin Lab/Projects/Worm Lifespan Robot/WormWatcher/N2_stability/N2_baseline_1/N2_stab1'
    
    % path to ROI directory folder (contains a .mat file)
    % should be defined
    
    % Open the folder and find each specific day - natsort
    exp_folder_struct=dir(this_experiment_folder);
    exp_folder_struct(ismember( {exp_folder_struct.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
    not_dir_idx = 1:length(exp_folder_struct);
    for i = 1:length(exp_folder_struct)
        if exp_folder_struct(i).isdir==false
            not_dir_idx(i) = 0;
            % get rid of everything in the struct that isnt a folder
        end
    end
    exp_folder_struct = exp_folder_struct(nonzeros(not_dir_idx));
    
    % create a new folder that will be the storage place for all 'raw-data'
    mkdir(data_storage, 'raw_data');
    mkdir('results');
    
    % define where the sessions data will be stored
    save_peaks_name = [data_storage 'raw_data/peaks.mat'];
    
    % if the user chooses this then each day will be parsed for the amount of
    % sessions and allow to update the base files
    if start_from_scratch
        disp('Creating new session data')
        % This will find the number of sessions/days/pre-processing stacks
        [sess_per_day,pks,locs] = find_number_of_sessions(exp_folder_struct,show_plots_peaks,overwrite_bad_images);
        save(char(save_peaks_name),'sess_per_day','pks','locs');
        %     check_for_focus(exp_folder_struct,overwrite_bad_images,sess_per_day,pks,locs)
    else
        % if not from scratch, then try and load the previously made session
        % information, if it isnt possible to load, then it will run the script
        % to find the individual sessions
        try load(char(save_peaks_name))
            disp('Session information found in files or workspace')
        catch
            [sess_per_day,pks,locs] = find_number_of_sessions(exp_folder_struct,show_plots_peaks,overwrite_bad_images);
            save(char(save_peaks_name),'sess_per_day','pks','locs');
            %         check_for_focus(exp_folder_struct,overwrite_bad_images,sess_per_day,pks,locs)
        end
    end
    
    % this find how far apart the different sessions are
    % important for upcoming session loading
    temp = sum(logical(locs),2);
    [temp,~] = find(temp>1);
    len_k=(locs(temp(1),2)-locs(temp(1),1)-1)/2;
    clear temp
    % mkdir([data_storage '/raw_data'])
    
    % this is used for the registrations
    se=strel('disk',40,4);
    
    % this loads the first images in each session's active period into the
    % 'stack', this is the preprocessing stack, and everything will be based
    % off of it
    L = max(sess_per_day(:));
    disp('Loading initial data');
    clear stack
    parfor i =1:length(exp_folder_struct)
        for j = 1:L
            if j<(sess_per_day(i)+1)
                temp_folder = dir(fullfile([exp_folder_struct(i).folder '/' exp_folder_struct(i).name],'*.png'));
                temp_folder(ismember( {temp_folder.name}, {'.', '..'})) = [];  %remove . and ..
                stack{i,j}=imread([temp_folder(locs(i,j)+1).folder '/' temp_folder(locs(i,j)+1).name]);
            end
        end
    end
    
    
    delete(fullfile(pwd,'temp_imgs/*'))
    delete(fullfile(pwd,'results/*'))
    
    k=1;
    for i =1:length(stack)
        for j = 1:L
            if j<(sess_per_day(i)+1)
                
                this_img_name = k;
                
                imwrite(stack{i,j},fullfile(pwd,'temp_imgs',[num2str(this_img_name) '.jpg']));
                
                k=k+1;
            end
        end
    end
    
    disp('Running neural network')
    [A,cmdout] = system('python yolo_test.py');
    
    disp(['Finished neural network with code: ' num2str(A)])
    
    k=0;
    clear sess_nums
    for i = 1:length(nonzeros(sum(locs,2)))
        for j = 1:length(nonzeros(sum(locs)))
            if (locs(i,j)>1)
                k=k+1;
                sess_nums(i,j) = k;
            end
        end
    end
    
    num_sess = max(sess_nums(:));
    stack2=cell(1,num_sess);
    for i=1:max(sess_nums(:))
        [a,b] = find(sess_nums == i);
        %     disp(num2str([a,b]))
        stack2{i} = stack{a,b};
    end
    
    newROIs=cell(size(stack));
    
    
    csv_path = fullfile(pwd,'results');
    csv_dir = dir(fullfile(csv_path,'*.csv'));
    
    [~,ndx,~] = natsort({csv_dir.name});
    csv_dir = csv_dir(ndx);
    
    se = strel('disk',5);
    
    [h,w] = size(stack{1,1});
    
    disp('Exporting network results to images');
    this_data_all = cell(1,length(stack2));
    for i = 1:length(stack2)
        
        [a,b] = find(sess_nums == i);
        
        this_csv_idx = i;
        
        this_img = stack2{i};
        
        this_result = table2array(readtable(fullfile(csv_dir(this_csv_idx).folder,csv_dir(this_csv_idx).name)));
        this_data_all{i} = this_result(:,1:4);
        
    end
    
    wells_of_240_plus = zeros(1,length(stack2));
    for i = 1:length(stack2)
        if length(this_data_all{i})>=240
            wells_of_240_plus(i) = 1;
        end
    end
    
    clear potential_bad_ROIs
    
    
    
    k = 1;
    for i = 1:length(stack2)
        
        [a,b] = find(sess_nums == i);
        
        this_data = this_data_all{i};
        
        % if there are not 240 data points
        if ~isequal(length(this_data),240)
            thisROI = zeros(h,w);
            potential_bad_ROIs(k) = i;
            k=k+1;
        else
            x = this_data(:,1);
            y = this_data(:,2);
            
            [thisROI,sess_is_bad] = gen_roi_from_nn_data(x,y,w,h);
            
            if sess_is_bad
                potential_bad_ROIs(k) = i;
                k=k+1;
            end
            
            if ~isequal(size(thisROI),size(stack2{i}))
                potential_bad_ROIs(k) = i;
                k=k+1;
            end
            
        end
        
        newROIs{a,b} = thisROI;
        
    end
    
    try
        disp(['Redoing ' num2str(sum(potential_bad_ROIs>0)) ' potentially bad ROIs']);
        
        good_bad_zero_vector = zeros(1,length(stack2));
        good_bad_zero_vector(potential_bad_ROIs) = 1;
        
        first_good_ROI_idx = find(good_bad_zero_vector==0,1,'first');
        [a2,b2] = find(sess_nums == first_good_ROI_idx);
        first_good_ROI = newROIs{a2,b2};
        first_good_sess = stack{a2,b2};
        for i = 1:length(potential_bad_ROIs)
            
            this_data = this_data_all{potential_bad_ROIs(i)};
            
            x = this_data(:,1);
            y = this_data(:,2);
            
            [a,b] = find(sess_nums == potential_bad_ROIs(i));
            
            this_sess = stack{a,b};
            
            fixed_ROI = attempt_to_fix_ROI(first_good_ROI,first_good_sess,this_sess,this_data);
            
            newROIs{a,b} = fixed_ROI;
            
            %         figure;
            %         imshow(fixed_ROI,[])
            %         title(potential_bad_ROIs(i))
            
        end
        
        
    catch
        potential_bad_ROIs = [];
        disp('All sessions ok')
    end
    
    
    
    disp('Saving created ROIs')
    save(char([data_storage 'raw_data/newROIs.mat']),'newROIs','-v7.3')
    
    elap=toc;
    disp([num2str(elap/60) ' minutes creating ROIs'])
    
    this_test = sort([1,randi(num_sess,1,4),max(sess_nums(:))],'ascend');
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    
    for i = 1:6
        [a,b] = find(sess_nums==this_test(i));
        
        subplot(2,3,i)
        imshow(double(stack{a,b}).*(newROIs{a,b}>0),[]);
        title(['New ROI example: ' num2str(i) ' day-' num2str(a) '-sess-' num2str(b)]);
    end
    
    drawnow
    
    % if ~isempty(newROIs{end,end})
    %     imshow(double(stack{end,end}).*(newROIs{end,end}>0),[]);
    % else
    %     imshow(double(stack{end,1}).*(newROIs{end,1}>0),[]);
    % end
    % title('New ROI example');
    
    
    disp(['Finished creating unique ROIs for experiment: ' exp_nm])
    
    
end

%%%%% if the ROI is bad run this code
% % %
% % % load('ROI_mini.mat')
% % % len = length(ROI)-1;
% % % A = figs(1:len); A = A(~cellfun('isempty',A)); figs = A;
% % % A = N_wells(1:len); A = A(~cellfun('isempty',A)); N_wells = A;
% % % A = ref_img(1:len); A = A(~cellfun('isempty',A)); ref_img = A;
% % % A = ROI(1:len); A = A(~cellfun('isempty',A)); ROI = A;
% % % clear len A
% % % save('ROI_mini.mat')


function [sess_per_day,pks,locs]=find_number_of_sessions(exp_dir,show_plots_peaks,overwrite_bad_images)

% hard coded might mess up eventually if more than 4 sessions detected
% if this messes up you can change it to 5 or more sessions
pks=zeros(length(exp_dir),4);
locs=zeros(length(exp_dir),4);

disp(['Finding daily identifications']);

sess_per_day = zeros(1,length(exp_dir));
parfor i = 1:length(exp_dir)
    
    % loads in one of the daily image folders
    temp_folder = dir(fullfile([exp_dir(i).folder '/' exp_dir(i).name],'*.png'));
    temp_folder(ismember( {temp_folder.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
    
    sums=(zeros(1,length(temp_folder)));
    
    % for each image, load it into ram
    for ii = 1:length(temp_folder)
        try
            temp_img = (imread([temp_folder(ii).folder '/' temp_folder(ii).name]));
            
            if mean2(temp_img) < 2
                error('bad img')
            end
            
        catch
            if overwrite_bad_images
                disp(['file ' temp_folder(ii).folder '/' temp_folder(ii).name ' corrupted'])
                temp_img = imread([temp_folder(ii).folder '/' temp_folder(ii-1).name]);
                imwrite(temp_img, [temp_folder(ii).folder '/' temp_folder(ii).name])
            else
                temp_img = 0;
                disp('More than one image in a row corrupted')
                error([temp_folder(ii).folder '/' temp_folder(ii).name]);
            end
        end
        %         avgs(ii) = mean(temp_img(:));
        % then add together every pixel value
        sums(ii) = sum(temp_img(:));
        
        
    end
    sums=gather(sums);
    
    % find if there is a significant difference (some are brighter than others)
    % If they are brighter than theyre the middle excitation light
    % can adjust values if this messes up so it does work
    [pks_temp,locs_temp]=findpeaks(sums,'MinPeakDistance',10,'Threshold',10000000);
    
    if isempty(locs_temp)
        disp([temp_folder(1).folder ' - Has no excitation light, using assumed spots'])
        
        switch length(temp_folder)
            case 25
                locs_temp = 13;
            case 50
                locs_temp = [13, 38];
            case 75
                locs_temp = [13, 38, 63];
        end
        
        pks_temp = ones(size(locs_temp));
        
    end
    
    % check to make sure the correct number of images are in the folder
    if rem(length(temp_folder),25)
        disp(['There is an incorrect number of images in ' temp_folder(1).folder ' please check'])
        error(['There is an incorrect number of images in ' temp_folder(1).folder ' please check'])
    end
    
    
    
    num_sessions = length(pks_temp);
    % % % %     disp(['found: ' num2str(num_sessions) ' sessions/peaks for day: ' num2str(i)]);
    
    % shouldnt really show each individual peak value
    % just a waste, but if you REALLY want to see the summations of each
    % image that be my guest
    if show_plots_peaks
        figure(i);
        plot(1:length(sums),sums,'b',locs_temp,pks_temp,'ro');title(['Day: ' num2str(i)])
        drawnow
    end
    
    % store data and export
    num_images=length(temp_folder);
    sess_per_day(i)=num_sessions;
    
    if length(pks_temp)==1
        
        pks_temp = [pks_temp 0 0 0];
        locs_temp = [locs_temp 0 0 0];
        
    elseif length(pks_temp)==2
        
        pks_temp = [pks_temp 0 0];
        locs_temp = [locs_temp 0 0];
        
    elseif length(pks_temp)==3
        
        pks_temp = [pks_temp 0];
        locs_temp = [locs_temp 0];
    end
    
    pks(i,:)=pks_temp;
    locs(i,:)=locs_temp;
end


end

