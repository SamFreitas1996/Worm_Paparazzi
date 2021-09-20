% WP_create_zstacks
% this function takes the imput images and runs through image processing
% steps to create a single representation (zstack) of each unique session

function [zstacks_paths,sess_nums,num_days] = ...
    WP_create_zstacks_testing(...
    exp_dir_path, dont_align_images,...
    save_data,compute_new_zstack_data,...
    normalize_intensities,start_sess,...
    calculate_optical_flow,...
    save_aligned_images,save_only_few,NoI,NoL,transform,init)

% get the experimental directory 
exp_dir = dir(exp_dir_path);
exp_dir(ismember( {exp_dir.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..

% get paths and names
[exp_fol,exp_nm,~]=fileparts(exp_dir_path);
data_storage = [exp_fol '/' exp_nm '-data/'];
regist_storage = [exp_fol '/' exp_nm '-registrations/'];

disp(['Starting data analysis for experiment: ' exp_nm])

% find and sort the stored data files
num_days = length(exp_dir);

% set up a couple variables
for i = 1:num_days
    temp_dirstep = dir([exp_dir(i).folder '/' exp_dir(i).name]);
    temp_dirstep(ismember( {temp_dirstep.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
    daily_path{i} = [exp_dir(i).folder '/' exp_dir(i).name];
    daily_dir{i}=temp_dirstep;
end

% find the number of sessions per each day
% This should all be done previously from WPdata but just in case
save_peaks_name = [data_storage 'raw_data/peaks.mat'];
show_plots_peaks = 0;
try
    load(char(save_peaks_name))
    disp('Session information found in files or workspace')
catch
    [sess_per_day,pks,locs] = find_number_of_sessions(exp_dir,show_plots_peaks);
    save(char(save_peaks_name),'sess_per_day','pks','locs');
end
% create len_k
% find the first day where there is enough data 
locs_temp = sum(logical(locs),2);
[locs_temp,~] = find(locs_temp>1);
try
    len_k=(locs(locs_temp(1),2)-locs(locs_temp(1),1)-1)/2;
catch
    disp('Error in len_k process, using default len_k = 12');
    len_k = 12;
end
clear temp

% load in the experiment specific ROIs
try
    if compute_new_zstack_data
        disp('Loading ROIs')
        load([data_storage 'raw_data/newROIs.mat']);
    else
        disp('Loading sess data')
    end
catch
    error('ROIs not found or improper path given, run WPdata w/ create_custom_ROIs = 1, or change where ROIs are located')
end

% clear unnecessary variables
clear figs

% set up a session counter
sess_counter=1;
total_num_sessions = sum(sess_per_day(:));

% use the ROIs if avaliable otherwise use the locations 
% sess nums represents what session goes to what day
if compute_new_zstack_data
    k=0;
    for i = 1:length(nonzeros(sum(locs,2)))
        for j = 1:length(nonzeros(sum(locs)))
            if ~isempty(newROIs{i,j})
                k=k+1;
                sess_nums(i,j) = k;
            end
        end
    end
else
        
    k=0;
    for i = 1:length(nonzeros(sum(locs,2)))
        for j = 1:length(nonzeros(sum(locs)))
            if locs(i,j)>0
                k=k+1;
                sess_nums(i,j) = k;
            end
        end
    end
end
% load in the censor
% load(char([data_storage '/raw_data/censor.mat']))

% if the saved images are to be stored then make a dir
if save_aligned_images
    mkdir(regist_storage)
end

% get 3 sessions for the "only save a few" variable choice 
first_reg   = [1,1];
middle_reg  = [round(num_days/2),2];
last_reg    = [num_days,2];

% individualized ROI normalization variable 
% in here because it shouldnt really be changed but givn the option 
indiv_ROI_norm = 1;

% reshape the ROI 2D array into a single vectored object array
num_sess = max(sess_nums(:));
if compute_new_zstack_data
    newROIs2=cell(1,num_sess);
    for i=1:max(sess_nums(:))
        [a,b] = find(sess_nums == i);
        %     disp(num2str([a,b]))
        newROIs2{i} = newROIs{a,b};
    end
end

clear newROIs

tic
% parfor loops through all the sessions to make the zstack datas 
if compute_new_zstack_data
% % %     start_sess = length(newROIs2) - sum(sess_per_day(end-1:end));
    %%%%% should be parfor
    parfor i=start_sess:num_sess
        
        % find which session number is this session 
        [a,b] = find(sess_nums == i);
        
        disp(['Processing data for day' num2str(a) ' session' num2str(b)]);
        
        % variables to load image data
        temp_dir = daily_dir{a};
        
        %%%%%%%%%%%%% Testing natsort
        [~,sorting_idx,~] = natsort({temp_dir.name});
        temp_dir = temp_dir(sorting_idx);
        
        img_idx_aft = (locs(a,b)+1:locs(a,b)+len_k);
        img_idx_bef = img_idx_aft-len_k-1;
        
        % set up overwriteable variables 
        stack_bef=cell(1,len_k);
        stack_aft=cell(1,len_k);
        centroids_bef = cell(1,len_k);
        centroids_aft = cell(1,len_k);
        
        % load in the image data from each session data 
        for k = 1:len_k
            stack_bef{k} = imread([temp_dir(img_idx_bef(k)).folder '/' temp_dir(img_idx_bef(k)).name]);
            stack_aft{k} = imread([temp_dir(img_idx_aft(k)).folder '/' temp_dir(img_idx_aft(k)).name]);
        end
        
        %disp(['Fixing ROI for day' num2str(a) ' session' num2str(b)]);
        %
        %         temp_ROI= (zeros(size(newROIs2{i})));
        %         temp_ROI_round = (round(newROIs2{i}));
        %         for k = 1:240
        %             aa=(temp_ROI_round==k);
        %             S = regionprops(aa, 'Area');
        %             L = bwlabel(aa);
        %             BW2 = ismember(L, find([S.Area] >= 10000));
        %             temp_ROI = temp_ROI + k*BW2;
        %         end
        %         newROIs2{i}=gather(temp_ROI);
        
        % find variance in the wells
        DoS = 4*std2(nonzeros(double(stack_aft{1}).*(newROIs2{i}>0)))^2;
        
        % if you want to align the images
        if ~dont_align_images
            
            % register the bef{1} to aft{1}
            % first use dft registration, and try ecc if that fails 
            try
                [A]=dtf_reg(stack_bef{1},stack_aft{1},0,0);
            catch
                try
                    [~, ~, A]=ecc(stack_bef{1},stack_aft{1}, NoL, NoI, transform, init);
                catch
                    disp(['IMPROPER REGISTRATION ON day' num2str(a) ' session' num2str(b)]);
                end
            end
            % filter the final registered image to preserve gradients but get
            % rid of background variance
            stack_bef{1}=imbilatfilt(double(A),DoS);
            
            % Register all the images to the base image
            for k =2:len_k
                % register stack before to stack after
                try
                    [A]=dtf_reg(stack_bef{k},stack_aft{1},0,0);
                catch
                    try
                        % if the first reg fails 
                        [~, ~, A]=ecc(stack_bef{k},stack_aft{1}, NoL, NoI, transform, init);
                        disp(['v2 on stack bef ' num2str([a,b])]);
                    catch
                        disp(['IMPROPER REGISTRATION ON day' num2str(a) ' session' num2str(b)]);
                        disp('Using unregistered image')
                        A = stack_bef{k};
                    end
                end
                % filter the registered iamge
                stack_bef{k}=imbilatfilt(double(A),DoS);
                % register stack_aft to the first image
                try
                    [ecc_temp1]=dtf_reg(stack_aft{k},stack_aft{1},0,0);
                catch
                    try
                        [~, ~, ecc_temp1]=ecc(stack_aft{k},stack_aft{1}, NoL, NoI, transform, init);
                        disp(['v2 on stack aft ' num2str([a,b])]);
                    catch
                        disp(['IMPROPER REGISTRATION ON day' num2str(a) ' session' num2str(b)]);
                        disp('Using unregistered image')
                        ecc_temp1 = stack_bef{k};
                    end
                end
                % [~, ~, ecc_temp2]=ecc(imhistmatch(stack_aft{k}, stack_aft{1}),stack_aft{1}, NoL, NoI, transform, init);
                % filter the registered image
                stack_aft{k}=imbilatfilt(double(ecc_temp1),DoS);
            end
            % finally filter the first image
            stack_aft{1}=imbilatfilt(double(stack_aft{1}),DoS);
            
        else
            % if no registration is needed (do not use this)
            for k = 1:len_k
                stack_aft{k} = double(stack_aft{k});
                stack_bef{k} = double(stack_bef{k});
                %                 first_image = stack_aft{1};
            end
            
            A = 0;
            
        end

        % this is to normalize the individual images to the session means 
        if normalize_intensities
            % first measure the focus of the image to make sure its 
            % in focus and usable 
            [fm] = WP_measure_focus([stack_bef stack_aft],0,0,num2str([a,b]));
            
            % if there is something wrong 
            if sum(fm<.7) || sum(fm<.7)<10
                
                % check for outliers in focus 
                focus_outliers = isoutlier(fm,'median');
                check_fm = focus_outliers.*(fm<.7);
                
                % if the outlers line up with the unfocused images
                if sum(check_fm)
                    disp(['Day' num2str(a) ' session' num2str(b) ' --' num2str(sum(fm<.7)) ' images potentially out of focus']);
                    
                    % replace the out of focus images 
                    focus_bad_images = nonzeros((1:(len_k*2)).*check_fm);
                    for k = 1:length(focus_bad_images)
                        if focus_bad_images(k) > len_k
                            bad_img = focus_bad_images(k)-len_k;
                            if ~isequal(bad_img,len_k)
                                stack_aft{focus_bad_images(k)-len_k} = stack_aft{focus_bad_images(k)-len_k+1};
                            else
                                stack_aft{focus_bad_images(k)-len_k} = stack_aft{focus_bad_images(k)-len_k-1};
                            end
                        else
                            
                            bad_img = focus_bad_images(k);
                            if ~isequal(bad_img,len_k)
                                stack_bef{focus_bad_images(k)} = stack_bef{focus_bad_images(k)+1};
                            else
                                stack_bef{focus_bad_images(k)} = stack_bef{focus_bad_images(k)-1};
                            end
                        end
                    end
                end
                
                
            end
            
            
            % now that the focus issue are resolved 
            % time to normalize the images to each other 
            
            % find the 2nd degree means of the base images 
            ref_bef = mean2(stack_bef{1});
            ref_aft = mean2(stack_aft{1});
            
            % initalize normalization to the first image mean values
            for k = 2:len_k
                stack_bef{k} = stack_bef{k}/(mean2(stack_bef{k})/ref_bef);
                stack_aft{k} = stack_aft{k}/(mean2(stack_aft{k})/ref_aft);
            end
            
            
            % individual ROI normalization (intensity equalization) across the 240 wells 
            if indiv_ROI_norm
                
                % create a mean image
                locs_temp = [stack_aft stack_bef];
                mean_img = mean((cat(3,locs_temp{1:end})),3);
                
                % use the mean image from the entire session
                scaling_ROI = zeros(size(newROIs2{i}));
                for k = 1:max(newROIs2{i}(:))
                    ROI_seg = mean_img.*(newROIs2{i}==k);
                    seg_mean = mean(nonzeros(ROI_seg(:)));
                    if isnan(seg_mean)
                        seg_mean = 0;
                    end
                    scaling_ROI = scaling_ROI + seg_mean*(newROIs2{i}==k);
                end
                % get an ROI for scaling the images 
                scaling_ROI = scaling_ROI/max(scaling_ROI(:));
                
                % isolation of the ROIs
                iso_ROI = (newROIs2{i}>0);
                
                % divide by the scaling ROI, moltiply by the isolation ROI
                % then get rid of all the NaN values and replace them with
                % 0 doubles 
                for k = 1:length(stack_aft)
                    stack_aft{k} = (stack_aft{k}./scaling_ROI).*iso_ROI;
                    stack_aft{k}(isnan(stack_aft{k})) = 0;
% % % %                     stack_bef{k} = stack_aft{k}.*scaling_ROI;
                    stack_bef{k} = (stack_bef{k}./scaling_ROI).*iso_ROI;
                    stack_bef{k}(isnan(stack_bef{k})) = 0;
                end
            end
            
        end
        
        % now that normalization is done time to create the zstacks 
        
        % create the first and last images for saving
        first_image = stack_bef{1};
        last_image = stack_aft{end};
        
        % find medain image from each side of the experiment
        median_img_aft=(median((cat(3,stack_aft{1:len_k})),3));
        median_img_bef=(median((cat(3,stack_bef{1:len_k})),3));
        
        % Remove a scaled median from all the images and create a 2D zstack
        
        zstack_aft=(zeros(size(stack_aft{1})));
        zstack_bef=(zeros(size(stack_aft{1})));
                
        for k = 1:len_k
            % remove median of the image stack
            temp1 = (stack_aft{k}) - median_img_aft*(1.1);
            temp2 = (stack_bef{k}) - median_img_bef*(1.1);
            
            % remove negative numbers - necessary
            if indiv_ROI_norm
                temp1(temp1<0)=0;
                temp2(temp2<0)=0;
            else
                temp1(temp1<1)=0;
                temp2(temp2<1)=0;
            end
            
            % slight area filtering 
            temp1 = temp1.*(bwareaopen(temp1>1,25,4));
            temp2 = temp2.*(bwareaopen(temp2>1,25,4));
                        
            if calculate_optical_flow
                centroids_aft{k} = WP_find_centroids(temp1,newROIs2{i});
                centroids_bef{k} = WP_find_centroids(temp2,newROIs2{i});
            end
            % stackasaurus
            zstack_aft = zstack_aft + temp1;
            zstack_bef = zstack_bef + temp2;
        end
        
        % create the save anem
        save_name = [data_storage 'raw_data/day' num2str(a) '_session' num2str(b) '.mat'];
        zstacks_paths{i} = save_name;
        thisROI=newROIs2{i};
        % how to save
        well_movements=gather((zstack_aft).*(thisROI>0));
        if save_data
            % % % % %             disp(['Saving data for day' num2str(a) ' session' num2str(b)]);
            parsave_WP(char(save_name),gather(zstack_aft),gather(zstack_bef),thisROI,first_image,last_image,centroids_aft,centroids_bef);
        end
        if save_aligned_images
            if save_only_few
                if isequal(first_reg,[a,b]) || isequal(middle_reg,[a,b]) || isequal(last_reg,[a,b])
                    save_name_registrations = [regist_storage 'day' num2str(a) '_session' num2str(b) '.mat'];
                    parsave_WP_registrations(save_name_registrations,stack_bef,stack_aft);
                end
            else
                save_name_registrations = [regist_storage 'day' num2str(a) '_session' num2str(b) '.mat'];
                parsave_WP_registrations(save_name_registrations,stack_bef,stack_aft);
            end
        end
        % will show the 'well movements' if allowed
        % writes an image to the save destination, not just a data file
        imwrite(well_movements/max(well_movements(:)),[data_storage 'raw_data/day' num2str(a) '_session' num2str(b) '.png']);
        
    end
    
    
else
    % if you dont need new zstacks then
    % just load some variables 
    for i=start_sess:num_sess
        [a,b] = find(sess_nums == i);
        save_name = [data_storage 'raw_data/day' num2str(a) '_session' num2str(b) '.mat'];
        zstacks_paths{i} = save_name;
    end
end
toc

end




