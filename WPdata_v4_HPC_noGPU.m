% WP ROIs and data setups

% Worm Paparazzi data setup and preprocessing 
% Creates custom per-basis ROIs for each movement sessions
% developed by Samuel Freitas
% December 2019 
% Sutphin Lab - University of Arizona - 2019
% must have a CUDA enabled GPU installed

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
experiment_folder = uigetdir('/groups/sutphin/', "select folder with the indivudual days");
if sum(experiment_folder=='.')
    disp('There was a period detected in the file name, renaming to _');
    experiment_folder_new = strrep(experiment_folder,'.','_');
    movefile(experiment_folder,experiment_folder_new);
    experiment_folder = experiment_folder_new;
end
[exp_fol,exp_nm,~]=fileparts(experiment_folder);
data_storage = [exp_fol '/' exp_nm '-data/'];
disp(['Creating unique ROIs for experiment: ' exp_nm])
% example
% experiment_folder='//fs.mcb.arizona.edu/labsupport/Sutphin Lab/Projects/Worm Lifespan Robot/WormWatcher/N2_stability/N2_baseline_1/N2_stab1'

% path to ROI directory folder (contains a .mat file)
% should be defined 

ROI_images_storage = char(ROI_images_storage);
ROI_refrence_path = char(ROI_refrence_path);
create_custom_ROIs_path = char(create_custom_ROIs_path);
try 
    load(ROI_refrence_path);
catch
    disp('Could not load previous ROIs, user must create some');
    create_custom_ROIs = 1;
end
clear figs

% Open the folder and find each specific day - natsort
exp_folder_struct=dir(experiment_folder);
exp_folder_struct(ismember( {exp_folder_struct.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
for i = 1:length(exp_folder_struct)
    if exp_folder_struct(i).isdir==false
        exp_folder_struct(i)=[]; 
        % get rid of everything in the struct that isnt a folder
    end
end

% create a new folder that will be the storage place for all 'raw-data'
mkdir(data_storage, 'raw_data');

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
len_k=(locs(2,2)-locs(2,1)-1)/2;
% mkdir([data_storage '/raw_data'])

% ecc setup variables
% these shouldnt be used by the program, but im keeping them in.....just in case
% for very basic image registration
% NoI = [60,3,3,3]; % number of iterations
NoI = [100,3,3,3]; % number of iterations
NoL = 6;  % number of pyramid-levels % changed to 4????????
transform = 'affine';
init=[eye(2) 20*ones(2,1)];%translation-only initialization



% this is used for the registrations 
se=strel('disk',40,4);



% this loads the first images in each session's active period into the
% 'stack', this is the preprocessing stack, and everything will be based
% off of it
L = max(sess_per_day(:));
disp('Loading initial data');
parfor i =1:length(exp_folder_struct)
    for j = 1:L
        if j<(sess_per_day(i)+1)
            temp_folder = dir(fullfile([exp_folder_struct(i).folder '/' exp_folder_struct(i).name],'*.png'));
            temp_folder(ismember( {temp_folder.name}, {'.', '..'})) = [];  %remove . and ..
            stack{i,j}=imread([temp_folder(locs(i,j)+1).folder '/' temp_folder(locs(i,j)+1).name]);
        end
    end
end

tempA = (double(stack{1,1}));
regist_approx_temp = zeros(size(ref_img));
for k = 1:length(ref_img)
    try
        R=corrcoef(tempA,(double(ref_img{k})));
    catch
        R=corrcoef(double(stack{1,1}),(double(ref_img{k})));
    end
    
    regist_approx_temp(k)=gather(R(2,1));
end

[val,idx] = sort(regist_approx_temp,'descend');

sess_reg_idx1=idx(1);

refrence_to_past_ROIs = (val>.75);

if sum(refrence_to_past_ROIs)
    disp('Found a potentially good ROI previously made');
    
    create_custom_ROIs=0;
    
    sess_reg_idx2=idx(2);
    sess_reg_idx3=idx(3);
    
end


if create_custom_ROIs
    % this uses a a differntial algorithm to find if there is any
    % significant difference in any of the days, that would require a
    % different ROI on that day
    
    pics_to_register_on=1;
    % pics_to_register_on - finds what images from the stack are potentially the best
    % pic_number - determines where those images are in the stack
    
    % NOTE: this will show a plot of how similar each session is compared
    % to the first session. From these differences you can determine if
    % there should be additional custom ROIs created by the user. 
    
    % finds where the 'stack' and best potential pictures are 
    % chnaged to just the first image 
    
    idx_day=1;
    idx_sess=1;
    
    %%%%%%%% How this little system works is:
    % 1. loads the ROI_images_storage folder 
    % 2. moves any and all previously used images to 'old'
    % 3. moves and renames the best potential images for new registrations to
    % - that ROI_images_storage folder 
    % 4. Runs the create_custom_ROIs function and then loads the new ROIs

    
    temp_folder = dir(fullfile(ROI_images_storage,'*.png'));

    if isequal(length(temp_folder),1)
        % if there is only one picture in the folder
        mkdir([ROI_images_storage '/old']);
        movefile([temp_folder.folder '/' temp_folder.name],[ROI_images_storage '/old'])
        
        for i = 1:length(pics_to_register_on)
            imwrite(stack{idx_day(i),idx_sess(i)},[ROI_images_storage '/' exp_nm '_ROI' num2str(i) '.png']);
        end
        
    elseif isequal(length(temp_folder),0)
        % if there are no pictures in the folder
        mkdir([ROI_images_storage '/old']);
        for i = 1:length(pics_to_register_on)
            imwrite(stack{idx_day(i),idx_sess(i)},[ROI_images_storage '/' exp_nm '_ROI' num2str(i) '.png']);
        end
    else 
        % if there are multiple pictures in the folder
        mkdir([ROI_images_storage '/old']);
        
        for i=1:length(temp_folder)
            movefile([temp_folder(i).folder '/' temp_folder(i).name],[ROI_images_storage '/old'])
        end
        for i = 1:length(pics_to_register_on)
            imwrite(stack{idx_day(i),idx_sess(i)},[ROI_images_storage '/' exp_nm '_ROI' num2str(i) '.png']);
        end
    
    end
    % do you want to build a ROI? 
    % must sing this to the tune of Frozen 
    
    % runs the createCustomROIs program, necessary to actually make new ROIs from the files
    run(create_custom_ROIs_path)
    % then loads that file that is created
    % assuming you correctly followed directions and added to the previous
    % ROI, and increased the ROI fidelity 
    % necessary to get the updated ROIs
    load(ROI_refrence_path); 
    
    close all
    
    tempA = (double(stack{1,1}));
    regist_approx_temp = zeros(size(ref_img));
    for k = 1:length(ref_img)
        try
            R=corrcoef(tempA,(double(ref_img{k})));
        catch
            R=corrcoef(double(stack{1,1}),(double(ref_img{k})));
        end
        regist_approx_temp(k)=gather(R(2,1));
    end
    
    [val,idx] = sort(regist_approx_temp,'descend');
    
    sess_reg_idx1=idx(1);
end
% else
%     [pics_to_register_on,pic_number]=best_potential_regist(stack,sess_per_day,experiment_folder);
% end

% This loop finds what ROI is closest to each image in the 'stack'
% Must have a decently powerful cuda (nvidia) GPU installed and working

save(char([data_storage 'raw_data/sess_reg_idx.mat']),'sess_reg_idx1');
clear R regist_approx_temp tempA


%%%%%%%%%%%%%% this is the main part of the custom ROI creation
% FYI image registration is just a fancy way of saying "lining up two
% images using software", much harder than it seems :/
disp('Creating custom ROIs for: day number, session number')

newROIs=cell(size(stack));
parfor i = 1:length(exp_folder_struct)
    
    
    for j = 1:L
        if j<(sess_per_day(i)+1)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%% This is for when all three attempts fail
            try
                
                
                % Creates the mask the same way as before
                maskA=(imclose(ROI{sess_reg_idx1},se)>0);
                movingImgA=maskA.*double(ref_img{sess_reg_idx1});
                
                % creates a bounding box from the 'cut-outs'
                s=regionprops(movingImgA>0,'basic');
                
                xMin = ceil(s.BoundingBox(1));
                xMax = xMin + s.BoundingBox(3) - 1;
                yMin = ceil(s.BoundingBox(2));
                yMax = yMin + s.BoundingBox(4) - 1;
                
                % Then this removes all the wells from large images
                % and removes everything that isnt the wells
                cutImg=ref_img{sess_reg_idx1}(yMin:yMax,xMin:xMax);
                
                % then you run a normalized cross correlation
                % across the entire image
                % creates a heatmap that shows where the center of
                % the wells is in relation to the images
                try
                    c = normxcorr2((cutImg),(stack{i,j}));
                    c=gather(c);
                catch
                    c = normxcorr2((cutImg),(stack{i,j}));
                end
                [ypeak,xpeak] = find(c==max(c(:)));
                yoffSet = ypeak-size(cutImg,1);
                xoffSet = xpeak-size(cutImg,2);
                
                ROIA = zeros(size(ROI{1}));
                
                % centers the most relevant ROIs on the actual
                % images and creates a new custom ROI from that
                % session
                ROIA(yoffSet:(yoffSet+size(cutImg,1)-1),xoffSet:(xoffSet+size(cutImg,2)-1))=...
                    ROI{sess_reg_idx1}(yMin:yMax,xMin:xMax);
                
                newROIs{i,j}=ROIA;
                
% % % %                 disp(['Success for: ' num2str(i) ',' num2str(j)]);
                
            catch
                disp(['Final Attempt for ' num2str(i) ',' num2str(j) ', using closest approximation'])
                newROIs{i,j}=ROI{sess_reg_idx1};
            end
            
            try
                close(h)
            catch
            end
            if show_progress_images
                %             h=figure(1);
                %             imshow(double(stack{i,j}).*(newROIs{i,j}>0),[]); title([num2str(i) ',' num2str(j)])
                %             drawnow;
                h = figure('OuterPosition',...
                    [-5.66666666666667 34.3333333333333 1293.33333333333 706.666666666667]);
                
                % Create axes
                axes1 = axes('Parent',h,...
                    'Position',[0.09 0.0863436123348018 0.819672131147541 0.881057268722467]);
                axis off
                hold(axes1,'on');
                
                % Create image
                image(double(stack{i,j}).*(newROIs{i,j}>0),'Parent',axes1,'CDataMapping','scaled');title([num2str(i) ',' num2str(j)])
                box(axes1,'on');
                axis(axes1,'ij');
                % Set the remaining axes properties
                set(axes1,...
                    'DataAspectRatio',[1 1 1],'Layer','top','TickDir','out');
                drawnow
            end
            
            
        end
    end
    
    
end

disp('Saving created ROIs')
save(char([data_storage 'raw_data/newROIs.mat']),'newROIs','-v7.3')

elap=toc;
disp([num2str(elap/60) ' minutes creating ROIs'])

figure; 
if ~isempty(newROIs{end,end})
    imshow(double(stack{end,end}).*(newROIs{end,end}>0),[]);
else
    imshow(double(stack{end,1}).*(newROIs{end,1}>0),[]);
end
title('New ROI example');


disp(['Finished creating unique ROIs for experiment: ' exp_nm])

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
                imwrite(imread([temp_folder(ii).folder '/' temp_folder(ii-1).name]), [temp_folder(ii).folder '/' temp_folder(ii).name])
            else
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
    
    % check to make sure the correct number of images are in the folder
    if rem(length(temp_folder),25)
        disp(['There is an incorrect number of images in ' temp_folder(1).folder ' please check'])
        error('fix please')
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
        locs_temp = [locs_temp 0 0]
        
    elseif length(pks_temp)==3
        
        pks_temp = [pks_temp 0];
        locs_temp = [locs_temp 0];
    end
    
    pks(i,:)=pks_temp;
    locs(i,:)=locs_temp;
end


end


function [pics_to_register_on,pic_number]=best_potential_regist(stack,sess_per_day,experiment_folder)

disp('finding the best approximate registrations for images (this might take a couple minutes)')
[length_stack,~] = size(stack);
k=1;

% changes the stack from a 2D cell, to a 1xN, easier for looping purposes
for i=1:length_stack
    for j=1:sess_per_day(i)
        stack2{k}=stack{i,j};
        pic_number(i,j)=k;
        k=k+1;
    end
end

% iterate through each image and compare it to the first in the stack
% this will tell you how similar or dissimilar they are
% And that determines if you need to create X many custom ROIs
tempB = (double(stack2{1}));
regist_app = zeros(1,length(stack2));
for i=1:length(stack2)
    R=corrcoef((double(stack2{i})),tempB);
    regist_app(i)=gather(R(2,1));
end
x=1:length(stack2);
% TF=ischange(smooth(regist_app,'sgolay'),'variance','MaxNumChanges',6);

% this is where the the outliers are found 
TF=isoutlier(diff(regist_app),'mean');

% just a bunch of if statesments to make sure that the isoutlier 
% function is working properly, and just if there is somehting fishy then
% these should capture the weirdness 
a=x(TF);
try
    if a(1)==1
        a=[1 a(2:end)+1];
    elseif isempty(a)
        a=1;
    else
        a=[1 a+1];
    end
catch
    a=1;
end

% gimme that PLOTTTTT
title_graph = regexprep(experiment_folder, '//', '////');

figure; plot(x,regist_app,x(TF),regist_app(TF),'ro',a, regist_app(a), 'b*');
legend('R-corrcoef','Detected outliers','Where to make registrations')
title(title_graph)

disp(['Register on ' num2str(a)])


pics_to_register_on=a;



end

function check_for_focus(exp_dir,overwrite_bad_images,sess_per_day,pks,locs)
imgs_per_sess = locs(1,2)-locs(1,1);
if overwrite_bad_images
    for i = 1:length(exp_dir)
        
        focus_measure = zeros(1,length(temp_folder));
        
        temp_folder = dir(fullfile([exp_dir(i).folder '/' exp_dir(i).name],'*.png'));
        temp_folder(ismember( {temp_folder.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
        
        for ii = 1:sess_per_day(i)
            
            for iii = locs(i,ii)-12:locs(i,ii)+12
                try
                    temp_img = (imread([temp_folder(iii).folder '/' temp_folder(iii).name]));
                catch
                    disp('something broke');
                end
                [r,c] = size(temp_img);
                
                r_center = round(r/2);
                c_center = round(c/2);
                
                xo = r_center-250;
                yo = c_center-250;
                w = 500;
                h = 500;
                
                roi = [xo yo w h];
                focus_measure(iii) = double(fmeasure(temp_img, 'VOLA' , roi));
                
                
            end
            focus_measure(locs(i,ii)) = focus_measure(locs(i,ii)-1);
            
            focus_measure(locs(i,ii)-12:locs(i,ii)+12) = focus_measure(locs(i,ii)-12:locs(i,ii)+12)/max(focus_measure(locs(i,ii)-12:locs(i,ii)+12));
            
            figure(ii)
            plot(focus_measure(locs(i,ii)-12:locs(i,ii)+12))
        end
        

    end
end

end
