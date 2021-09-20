
function [censored_wells_runoff_var,censored_wells_runoff_nn,potential_healthspans_days,any_nn_activity] = WP_runoff_nn_daily(data_storage,exp_nm,censored_wells,sess_nums,skip_nn_runoff,final_data_export_path,full_exp_name)
nn_confidence_thresh = 0.5;

disp(['Runoff and health calculations for ' char(exp_nm)])

if ~skip_nn_runoff
    % % % load('setup_testing.mat')
    load([data_storage 'processed_data/norm_activity.mat']);
    load([data_storage 'processed_data/potential_lifespans.mat']);
    
    
    % load in session information
    %sess_diff = raw_sess_data_aft - raw_sess_data_bef;
    
    % number_loaded = 5;
    use_daily_inst_of_sess = 1;
    
    if use_daily_inst_of_sess
        % load days
        number_loaded = max(sess_nums(:));
        % check output (only nn results)
        output_check = 1;
        disp('Creaing data for neural network')
        % load diff imgs and ROIs
        [diff_imgs,number_loaded] = load_diff(data_storage,number_loaded);
        [newROIs2] = load_ROIs2(data_storage,number_loaded);
        
        % create data
        [~,images] = daysXimgs(1:240,number_loaded,newROIs2,diff_imgs,output_check,exp_nm,sess_nums);
        disp('running neural network')
        % run NN
%         [error_message,cmdout] = system('python tf2_multithread.py');
        [error_message,cmdout] = system('python yolo_test_worm_batching.py');
        [output] = covert_yolo_csv_to_cell();
        
        [output] = filter_nn_output(output,error_message,sess_nums,nn_confidence_thresh);
        
        disp('Finished running neural network, exporting data')
%         nnRes = cellfun(@str2double,strsplit(cmdout));
%         nnRes = nnRes(~isnan(nnRes));
        
        nnRes = output(:,end);

        % transform the output into an array
        worms_nn_predicted = flip(rot90(reshape(nnRes,[length(sess_nums),240]),3),2);
        
    else
        number_loaded = 5;
        output_check = 1;
        disp('Creaing data for neural network')
        [diff_imgs] = load_diff(data_storage,number_loaded);
        [newROIs2] = load_ROIs2(data_storage,number_loaded);
        
        [init_imgs,images] = sessXimgs(1:240,number_loaded,newROIs2,diff_imgs,output_check,exp_nm,sess_nums);
        disp('running neural network')
        [~,cmdout] = system('python tf2_test.py');
        nnRes = cellfun(@str2double,strsplit(cmdout));
        nnRes = nnRes(~isnan(nnRes));
        worms_nn_predicted = flip(rot90(reshape(nnRes,[number_loaded,240]),3),2);
    end
    
    % if need more training data (dont)
    create_new_training_data = 0;
    if create_new_training_data
        disp('Creating new training data')
        create_new_training_data_nn_unlabeled(worms_nn_predicted,images);
    end
    
else
    load(char([data_storage '/processed_data/runoff_worms']));
    load(char([data_storage 'processed_data/potential_lifespans']))
end

% take the first 5 sessions and if there are more than 1 worms predicted then it didnt
% initally run off. otherwise the worm most likely ran off initially
inital_runoff = logical( sum(worms_nn_predicted(:,1:5)>nn_confidence_thresh,2) < 2 );
any_nn_activity = logical(sum(worms_nn_predicted>nn_confidence_thresh,2));

% if there are more than 3 potential healthy days then the worm was present
% on the plate

% initalize
potential_healthspans_days = zeros(1,240);

% find healthspans of each worm
% this is defined as full motility of a worm
for i = 1:240
    % if the worm didnt run initally
    if ~inital_runoff(i)
        this_nn_predict = worms_nn_predicted(i,:)>nn_confidence_thresh;
        
        for j = 2:length(this_nn_predict)-1
            if this_nn_predict(j-1) == 1 && this_nn_predict(j+1) == 1 && this_nn_predict(j) == 0
                this_nn_predict(j) = 1;
            end
        end
        
        % filter the data to ommit any outliers
        this_nn_predict = medfilt1(double(this_nn_predict),3);
        
        % find the last time there is a worm
        this_health = find(this_nn_predict==1,1,'last');
        
        if ~isempty(this_health)
            % record
            potential_healthspans_days(i) = this_health + 1 ;
        end
    end
    
end

% find how close the life and health spans are
health_life_diff = abs(potential_lifespans_days-potential_healthspans_days);
experimental_runoff = zeros(size(inital_runoff));

for i = 1:240
    % if the heath and life spans are within a day of eachother than the
    % most ran
    if health_life_diff(i) < 1
        experimental_runoff(i) = 1;
    end
end
experimental_runoff = logical(experimental_runoff);

% result to the init imgs folder
if ~skip_nn_runoff
    [~,~] = nnRes_to_img(nnRes,images,240,number_loaded,...
        exp_nm,potential_healthspans_days,inital_runoff,...
        experimental_runoff,final_data_export_path,full_exp_name,...
        worms_nn_predicted,potential_lifespans_days,nn_confidence_thresh,output);
else
%     nnRes = reshape(worms_nn_predicted',[length(sess_nums)*240,1]);
%     [~,~] = nnRes_to_img(nnRes,images,240,number_loaded,exp_nm,potential_healthspans_days,inital_runoff,experimental_runoff,final_data_export_path,full_exp_name);
end
% save variables
censored_wells_runoff_nn = (inital_runoff');% | potential_runaway);
censored_wells_runoff_var = (experimental_runoff');

try
    save(char([data_storage '/processed_data/runoff_worms']),'censored_wells_runoff_var','censored_wells_runoff_nn','worms_nn_predicted','any_nn_activity','-append');
    save(char([data_storage 'processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','potential_healthspans_days','-append');
catch
    save(char([data_storage '/processed_data/runoff_worms']),'censored_wells_runoff_var','censored_wells_runoff_nn','worms_nn_predicted','any_nn_activity');
    save(char([data_storage 'processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','potential_healthspans_days');
    
end
disp([num2str(sum(logical(censored_wells_runoff_nn))) ' worms potentially ran away initially on ' exp_nm])
disp([num2str(sum(logical(censored_wells_runoff_var))) ' worms potentially ran away over time on ' exp_nm])


end

function [diff_imgs,number_loaded] = load_diff(data,number_loaded)

diff_dir = dir(fullfile([data '/raw_data/diff_imgs'],'*.png'));
[~,sort_idx,~] = natsort({diff_dir.name});
diff_dir = diff_dir(sort_idx);
diff_dir(ismember( {diff_dir.name}, {'.', '..'})) = [];
if number_loaded
    diff_imgs = cell(1,number_loaded);
else
    diff_imgs = cell(1,length(diff_dir));
end

if number_loaded > length(diff_dir)
    disp('Missmatch of sessions and diff images');
    number_loaded = length(diff_dir);
end

for i = 1:number_loaded
    diff_imgs{i} = imread([diff_dir(i).folder '/' diff_dir(i).name]);
end

end

function [newROIs2] = load_ROIs2(data,number_loaded)

ROI2_dir = dir(fullfile([data '/raw_data'],'*.mat'));
[~,sort_idx,~] = natsort({ROI2_dir.name});
ROI2_dir = ROI2_dir(sort_idx);
ROI2_dir(ismember( {ROI2_dir.name}, {'.', '..','newROIs.mat','peaks.mat','sess_reg_idx.mat','censor.mat','nth_sess_activity.mat'})) = [];  %remove . and ..

if number_loaded
    newROIs2 = cell(1,number_loaded);
else
    newROIs2 = cell(1,length(ROI2_dir));
end
for i = 1:length(newROIs2)
    a = load([ROI2_dir(i).folder '/' ROI2_dir(i).name],'thisROI');
    newROIs2{i} = a.thisROI;
end

end

function [init_img, daily_img_entire] = daysXimgs(ROI_nums,num_images,newROIs,diff_imgs,output_check,exp_nm,sess_nums)

temp_imgs_path = [pwd '/temp_imgs'];
mkdir(temp_imgs_path);

% remove anything prevos
img_dir = dir(fullfile(temp_imgs_path,'*.jpg'));
parfor i = 1:length(img_dir)
    delete(fullfile(img_dir(i).folder,img_dir(i).name))
end

% find high and lowbound
if num_images >1
    lowBound = 1;
    highBound = num_images;
else
    lowBound = 1;
    highBound = length(diff_imgs);
    num_images = highBound;
end

k=1;
for i = ROI_nums
    for j = 1:length(newROIs)
        img_nums(i,j) = k;
        k=k+1;
    end
end

images_large = cell(1,length(ROI_nums));

% isolate each well
images = cell(length(ROI_nums),num_images);
parfor j = lowBound:highBound
    
    thisROI = newROIs{j};
    thisDiff = diff_imgs{j};
    try
        for i = ROI_nums
            try
                s = regionprops(thisROI==i,'BoundingBox');
                xMin = ceil(s.BoundingBox(1));
                xMax = xMin + s.BoundingBox(3) - 1;
                yMin = ceil(s.BoundingBox(2));
                yMax = yMin + s.BoundingBox(4) - 1;
                images{i,j} = thisDiff(yMin:yMax,xMin:xMax);
            catch
                disp(['There was an error creating data on session ' num2str(j) ' well ' num2str(i)])
                s = regionprops(thisROI==120,'BoundingBox');
                try
                    error_zero_img = zeros(s.BoundingBox(3),s.BoundingBox(4),'uint8');
                catch
                    s = regionprops(thisROI==115,'BoundingBox');
                    error_zero_img = zeros(s.BoundingBox(3),s.BoundingBox(4),'uint8');
                end
                
                images{i,j} = error_zero_img;

            end
        end
    catch
        disp(['There was an error creating data on session ' num2str(j)])
        s = regionprops(thisROI==120,'BoundingBox');
        try
            error_zero_img = zeros(s.BoundingBox(3),s.BoundingBox(4),'uint8');
        catch
            s = regionprops(thisROI==115,'BoundingBox');
            try
                error_zero_img = zeros(s.BoundingBox(3),s.BoundingBox(4),'uint8');
            catch
                disp('using 205x250')
                error_zero_img = zeros(205,205,'uint8');
            end
        end
        for i = ROI_nums
            images{i,j} = error_zero_img;
        end
    end
end

img_counter = 1;

daily_img_entire = cell(240*length(sess_nums),1);

for i = 1:240
    
    % isolate each worm
    this_worm_sess_imgs = images(i,:);
    
    % create a cell array for filtering
    this_worm_sess_imgs2 = cell(size(this_worm_sess_imgs));
    
    for j = 1:length(this_worm_sess_imgs)
        
        [x1,x2] = size(this_worm_sess_imgs{j});
        
        if ~isequal(x1,x2)
            
            largest_x = max([x1,x2]);
            
            temp_zeros_array = zeros(largest_x,largest_x,'uint8');
            temp_zeros_array(1:x1,1:x2) = this_worm_sess_imgs{j};
            this_worm_sess_imgs{j} = temp_zeros_array;
            
        end
        
    end
    
    % create the filter
    med_image_worm_sess=(median((cat(3,this_worm_sess_imgs{1:highBound})),3));
    med_image_worm_sess = im2uint8(med_image_worm_sess/max(med_image_worm_sess(:)));
    
    for j = 1:length(this_worm_sess_imgs)
        % median filtering
        this_worm_sess_imgs2{j} = this_worm_sess_imgs{j}-med_image_worm_sess;
    end
    
    % reuse the same name and isolate each worm into the proper
    % day row and column
    this_worm_sess_imgs = cell(size(sess_nums));
    for j = 1:max(sess_nums(:))
        [a,b] = find(sess_nums == j);
        this_worm_sess_imgs{a,b} = this_worm_sess_imgs2{j};
    end
    
    % create a concatinated daily image
    daily_img = cell(length(sess_nums),1);
    for j = 1:length(sess_nums)
        
        % isolate
        this_day_all_imgs = this_worm_sess_imgs(j,:);
        % get rid of blank cells
        this_day_all_imgs = this_day_all_imgs(~cellfun('isempty',this_day_all_imgs));
        
        switch length(this_day_all_imgs)
            % if there is only one image
            case 1
                daily_img{j} = double(this_day_all_imgs{1});
                daily_img{j} = daily_img{j}/max(daily_img{j}(:));
                daily_img{j} = im2uint8(daily_img{j});
                % if there are only two images then
            case 2
                daily_img{j} = double(imabsdiff(this_day_all_imgs{1},this_day_all_imgs{2}));
                daily_img{j} = daily_img{j}/max(daily_img{j}(:));
                daily_img{j} = im2uint8(daily_img{j});
                % otherwise
            otherwise
                med_image_daily = (median((cat(3,this_day_all_imgs{1:length(this_day_all_imgs)})),3));
                for k = 1:length(this_day_all_imgs)
                    this_day_all_imgs{k} = this_day_all_imgs{k}-med_image_daily;
                end
                daily_img{j} = (sum((cat(3,this_day_all_imgs{1:length(this_day_all_imgs)})),3));
                daily_img{j} = daily_img{j}/max(daily_img{j}(:));
                daily_img{j} = im2uint8(daily_img{j});
        end
        
    end
    
    % expand those processed images into a single long array
    for j = 1:length(daily_img)
        if j==1
            daily_img{j} = insertText(daily_img{j},[10 10],num2str(i));
            daily_img_entire{img_counter} = daily_img{j};
        else
            daily_img_entire{img_counter} = daily_img{j};
        end
        img_counter = img_counter+1;
    end
    
    if output_check
        images_large{i} = imtile(daily_img,'GridSize',[1,length(daily_img)]);
    end
    
end

% write the long aray to images
parfor j = 1:length(daily_img_entire)
    imwrite(daily_img_entire{j},[temp_imgs_path '/' num2str(j) '.jpg']);
end

init_img = 0;

end

function [init_img, images2] = sessXimgs(ROI_nums,num_images,newROIs,diff_imgs,output_check,exp_nm,sess_nums)

temp_imgs_path = [pwd '/temp_imgs'];
mkdir(temp_imgs_path);

% remove anything prevos
img_dir = dir(fullfile(temp_imgs_path,'*.jpg'));
parfor i = 1:length(img_dir)
    delete(fullfile(img_dir(i).folder,img_dir(i).name))
end

% find high and lowbound
if num_images >1
    lowBound = 1;
    highBound = num_images;
else
    lowBound = 1;
    highBound = length(diff_imgs);
    num_images = highBound;
end

k=1;
for i = ROI_nums
    for j = 1:length(newROIs)
        img_nums(i,j) = k;
        k=k+1;
    end
end

o=1;
images = cell(length(ROI_nums),num_images);
images_large = cell(1,length(ROI_nums));

images = cell(length(ROI_nums),num_images);
parfor j = lowBound:highBound
    thisROI = newROIs{j};
    thisDiff = diff_imgs{j};
    for i = ROI_nums
        s = regionprops(thisROI==i,'BoundingBox');
        xMin = ceil(s.BoundingBox(1));
        xMax = xMin + s.BoundingBox(3) - 1;
        yMin = ceil(s.BoundingBox(2));
        yMax = yMin + s.BoundingBox(4) - 1;
        images{i,j} = thisDiff(yMin:yMax,xMin:xMax);
    end
end

images2 = cell(length(ROI_nums),num_images);
parfor i = ROI_nums
    theseImages = images(i,:);
    med_images=(median((cat(3,theseImages{1:highBound})),3));
    for j = 1:highBound
        
        tempImg = images{i,j} - med_images;
        
        tempImg(tempImg<0)=0;
        
        tempImg = double(tempImg)/max(max(double(tempImg)));
        
        if j==1
            %             images{i,j} = insertText(images{i,j}/max(max(images{i,j})),[10 10],num2str(i));
            images2{i,j} = insertText(tempImg,[10 10],num2str(i));
            theseImages{j} = images2{i,j};
        else
            images2{i,j} = tempImg;
            theseImages{j} = images2{i,j}
        end
        
        images2{i,j} = im2uint8(images2{i,j});
        
    end
    
    images_large{i} = imtile(theseImages,'GridSize',[1,num_images]);
end

parfor i = 1:(num_images*max(ROI_nums))
    [a,b] = find(img_nums == i);
    imwrite(images2{a,b},[temp_imgs_path '/' num2str(i) '.jpg']);
end

if output_check
    
    init_img = imtile(images_large,'GridSize',[max(max(newROIs{1})) 1]);
    
    init_img = im2uint8(init_img);
    
    mkdir([pwd '/init_imgs'])
    imwrite(init_img,[pwd '/init_imgs/' exp_nm '_init_img.png'])
    
else
    init_img = 0;
end

end


function [nnResult_img,large_images] = nnRes_to_img(...
    nnRes,images,num_wells,num_pics,exp_nm,potential_healthspans_days,...
    inital_runoff,experimental_runoff,final_data_export_path,...
    full_exp_name,worms_nn_predicted,potential_lifespans_days,...
    nn_confidence_thresh,output)

[rows,cols] = size(images);

% reshape the images array into a long array
if cols>1
    images = reshape(images',[num_wells*num_pics,1]);
else
    num_pics = rows/240;
end

for i = 1:length(images)
    
    this_nnRes = nnRes(i);
    
    this_nnRes(:,6:end,:)=[];
    
    xywh = [output(i,2:5)];
    xywh(3) = xywh(3)-xywh(1);
    xywh(4) = xywh(4)-xywh(2);
    
    if this_nnRes > nn_confidence_thresh
        images{i} = insertText(images{i},[150,10],this_nnRes,'BoxColor','green');
        images{i} = insertShape(images{i},'Rectangle',xywh,'Color','green');
    else
        images{i} = insertText(images{i},[150,10],this_nnRes,'BoxColor','red');
    end
    
end

o=1;
large_images = cell(1,num_wells);

any_nn_activity = logical(sum(worms_nn_predicted>nn_confidence_thresh,2));

for i = 1:num_pics:length(images)
    % create large image
    large_images{o} = imtile(images(i:(i+num_pics-1)),'GridSize',[1,num_pics]);
    if any_nn_activity(o)
        if ~inital_runoff(o)
            % if the worm didnt initally run
            x_row_health = potential_healthspans_days(o)*length(images{1}) - (100);
            if ~experimental_runoff(o)
                % if the worm didnt run during the experimnt
                large_images{o} = insertText(large_images{o},[x_row_health,30],'healthly end','BoxColor','cyan');
            else
                large_images{o} = insertText(large_images{o},[x_row_health,30],'healthy ran','BoxColor','magenta');
            end
        else
            % if the worm did initally run
            large_images{o} = insertText(large_images{o},[length(images{1})-(100),30],'initially ran','BoxColor','blue');
        end
    else
        large_images{o} = insertText(large_images{o},[length(images{1})-(150),30],'Nothing detected','BoxColor','white');
    end
    o=o+1;
end

nnResult_img = imtile(large_images,'GridSize',[length(images)/num_pics 1]);

nnResult_img = im2uint8(nnResult_img);

mkdir([pwd '/init_imgs'])
% imwrite(nnResult_img,[pwd '/init_imgs/' exp_nm '_nn_result.jpg'])
imwrite(nnResult_img,[final_data_export_path '/' full_exp_name '/' exp_nm '_nn_result.jpg']);

end