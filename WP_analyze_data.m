% WP - analyze data


function [raw_sess_data_aft, raw_sess_data_bef, raw_sess_data_integral,censored_wells2,runoff_cutoff2,raw_sess_data_aft_bw,raw_sess_data_bef_bw] = ...
    WP_analyze_data(data_storage,reduce_final_noise,runoff_cutoff,censored_wells,bw_analysis,final_data_export_path,full_exp_name)


mkdir([data_storage '/processed_data']);
mkdir([data_storage '/raw_data/diff_imgs'])
mkdir([data_storage '/processed_data/proc_zstacks']);

data_dir=dir(data_storage);
data_dir=data_dir(ismember( {data_dir.name},{'raw_data'}));
data_dir=dir([data_dir.folder '/' data_dir.name]);
data_dir=dir(fullfile(char(data_dir(1).folder),'*.mat'));
data_dir(ismember( {data_dir.name}, {'.', '..','nth_sess_activity.mat','newROIs.mat','peaks.mat','sess_reg_idx.mat','censor.mat'})) = [];  %remove . and ..


% sorts the names
data_names = natsort({data_dir.name});

nth_sess_data=zeros(1,240);
raw_sess_data_integral=(zeros(length(data_names),240));
raw_sess_data_bef=(zeros(length(data_names),240));
raw_sess_data_aft=(zeros(length(data_names),240));
raw_sess_data_aft_bw=(zeros(length(data_names),240));
raw_sess_data_bef_bw=(zeros(length(data_names),240));

incomplete_data_censor = cell(1,length(data_names));
% this is a parfor loop
parfor i = 1:length(data_names)
% for i = length(data_names)-5:length(data_names)
    
    disp(['Reading data for session: ' num2str(i)])
    
    
    % normalize for everything that isnt the first, as its the basis
    sess_data = load([data_dir(1).folder '/' data_names{i}]);
    
    % fix the ROI from warping
    % for some reason bwareaopen is not working on my GPU
    % so i had to make a custom one that shoudl run faster
    
    % summation of movement before and after excitation
    % initalize the interative variables
    try
        %sess_activity = (double(imfuse(gather(sess_data.zstack_bef),gather(sess_data.zstack_aft),'diff','Scaling','joint')));
        sess_activity_integral = imadd(gather(sess_data.zstack_bef),gather(sess_data.zstack_aft));
        
        if reduce_final_noise
            
            zstack_aft_temp = sess_data.zstack_aft;
            zstack_bef_temp = sess_data.zstack_bef;
            
            % find image gradients 
            grad_bef = imgradient(sess_data.first_image);
            grad_bef = (grad_bef/max(grad_bef(:)))*max(zstack_bef_temp(:));
            
            grad_aft = imgradient(sess_data.last_image);
            grad_aft = (grad_aft/max(grad_aft(:)))*max(zstack_aft_temp(:));
            
            % remove a scaled image gradient for noise reduction 
            zstack_bef_temp = zstack_bef_temp - grad_bef;
            zstack_bef_temp(zstack_bef_temp<0)=0;
            
            zstack_aft_temp = zstack_aft_temp - grad_aft;
            zstack_aft_temp(zstack_aft_temp<0)=0;
            
            zstack_bef_temp = bwareaopen((zstack_bef_temp>0),15).*zstack_bef_temp;
            zstack_aft_temp = bwareaopen((zstack_aft_temp>0),15).*zstack_aft_temp;
            
            sess_activity_integral = imadd(gather(zstack_bef_temp),gather(zstack_aft_temp));
            
            sess_activity_integral(1:10,:) = 0;
            
            %threshold_val = mean(nonzeros(sess_activity_integral)) + std(nonzeros(sess_activity_integral));
            
            threshold_val = 3; % 3
            
            sess_activity_integral = sess_activity_integral.*bwareaopen((sess_activity_integral>threshold_val),20,4);
            % find any pixels that are over 0 in value
            % then remove any "islands" that are over 15 pixels in value
            % then use that binary image to parse the previous data from the
            % sess_activity image/mat files
        end
        
        % create the difference image for each session for the neural
        % network 
        A=sess_data.first_image/max(sess_data.first_image(:));
        B=sess_data.last_image/max(sess_data.last_image(:));
        A_backg = imopen(A,strel('disk',5));
        B_backg = imopen(B,strel('disk',5));
        A_proc=(A-A_backg).*((A-A_backg)>0);
        B_proc=(B-B_backg).*((B-B_backg)>0);
        diff_img = imabsdiff(A_proc,imhistmatchn(B_proc,A_proc,256));
        
        % imshow(imadjust(AB,stretchlim(AB,[.50,.999])))
        
        % writes binary image
        imwrite(gather((sess_activity_integral>0).*(sess_data.thisROI>0)),char([data_storage 'processed_data/sess_' num2str(i) '.png']));
        % writes difference image
        imwrite(diff_img,char([data_storage 'raw_data/diff_imgs/sess_' num2str(i) '.png']));
        % writes zstack_processed image
        imwrite(sess_activity_integral/max(sess_activity_integral(:)),char([data_storage 'processed_data/proc_zstacks/sess_' num2str(i) '.png']))
        
        sess_activity_integral_mask = sess_activity_integral>0;
        
        if bw_analysis
            
            bw_sess_img_bef = (sess_data.zstack_bef.*sess_activity_integral_mask)>0;
            bw_sess_img_aft = (sess_data.zstack_aft.*sess_activity_integral_mask)>0;
            
            temp_idx = zeros(1,240);
            
            for j = 1:240
                
                loop_ROI = (sess_data.thisROI==j);
                
                if isequal(sum(loop_ROI(:)),0)
                    temp_idx(j) = 1;
                end
                
                raw_sess_data_bef_bw(i,j) = sum(sum((bw_sess_img_bef).*loop_ROI));
                raw_sess_data_aft_bw(i,j) = sum(sum((bw_sess_img_aft).*loop_ROI));
                
                raw_sess_data_bef(i,j) = 0;
                raw_sess_data_aft(i,j) = 0;
                raw_sess_data_integral(i,j) = raw_sess_data_bef_bw(i,j) + raw_sess_data_aft_bw(i,j);
            end
        else
            for j = 1:240
                
                loop_ROI = (sess_data.thisROI==j);
                
                raw_sess_data_bef_bw(i,j) = 0;
                raw_sess_data_aft_bw(i,j) = 0;
                
                raw_sess_data_bef(i,j) = sum(sum(sess_data.zstack_bef.*loop_ROI));
                raw_sess_data_aft(i,j) = sum(sum(sess_data.zstack_aft.*loop_ROI));
                raw_sess_data_integral(i,j) = raw_sess_data_bef(i,j) + raw_sess_data_aft(i,j);
            end
        end
        
        incomplete_data_censor{i} = temp_idx
        
    catch
        for j=1:240
            raw_sess_data_integral(i,j)=0;
            raw_sess_data_bef(i,j) = 0;
            raw_sess_data_aft(i,j) = 0;
        end
        disp(['There was an error on session ' num2str(i)])
    end
end

if runoff_cutoff == 0
    [max_acvivity_integrated,max_activity_index]=max(sum(raw_sess_data_integral,2));
    runoff_cutoff = max_activity_index;
    runoff_cutoff2 = runoff_cutoff;
    
end
disp('Creating incomplete data censor');

incomplete_data_censor_full = zeros(1,240);
for i = 1:length(incomplete_data_censor)
    
    incomplete_data_censor_full = incomplete_data_censor_full + incomplete_data_censor{i};
    
end

incomplete_data_censor_full = double(incomplete_data_censor_full>0);

% this is depreciated but for some reason i use variables generated here
% later on just for specific lengths and heights of data
% sess_data=load([data_dir(1).folder '/' data_names{runoff_cutoff}]);
%
% sess_activity_integral = imadd(gather(sess_data.zstack_bef),gather(sess_data.zstack_aft));
% if reduce_final_noise
%     sess_activity_integral = bwareaopen((sess_activity_integral>0),15).*sess_activity_integral;
%
% end
% thisROI = sess_data.thisROI;
% save(char([data_storage 'raw_data/nth_sess_activity']),'sess_activity_integral','thisROI');
% % save the 7th session for determining if the worms ran off in the
% % first couple days - 7th session is approx 48 hours on the machine
% activity_hmap = zeros(size(thisROI));
% censored_wells_runoff_depreciated = zeros(1,240) +1;
% for k = 1:240
%     nth_sess_data(k) = sum(sum(sess_activity_integral.*(thisROI==k)))*(~censored_wells{k});
%
%     if nth_sess_data(k)>1000
%         activity_hmap = activity_hmap + (nth_sess_data(k)*double(thisROI==k));
%         censored_wells_runoff_depreciated(k)=0;
%     end
%
% end
%
% censored_wells2 = double(logical(censored_wells_runoff_depreciated + censored_wells));

censored_wells2 = incomplete_data_censor_full;

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