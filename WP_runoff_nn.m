
function [censored_wells_runoff_var,censored_wells_runoff_nn] = WP_runoff_nn(data_storage,exp_nm,censored_wells,sess_nums)


% % % load('setup_testing.mat')
load([data_storage 'processed_data/norm_activity.mat']);
load([data_storage 'processed_data/potential_lifespans.mat']);


% load in session information 
%sess_diff = raw_sess_data_aft - raw_sess_data_bef;

% number_loaded = 5;

use_daily_inst_of_sess = 1;

if use_daily_inst_of_sess
    number_loaded = max(sess_nums(:));
    output_check = 1;
    disp('Creaing data for neural network')
    [diff_imgs] = load_diff(data_storage,number_loaded);
    [newROIs2] = load_ROIs2(data_storage,number_loaded);
    
    [~,images] = daysXimgs(1:240,number_loaded,newROIs2,diff_imgs,output_check,exp_nm,sess_nums);
    disp('running neural network')
    [~,cmdout] = system('python tf2_multithread.py');
    nnRes = cellfun(@str2double,strsplit(cmdout));
    nnRes = nnRes(~isnan(nnRes));
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

create_new_training_data = 0;
if create_new_training_data
    
    create_new_training_data_nn(worms_nn_predicted,images,number_loaded);
    
end

[~,large_images] = nnRes_to_img(nnRes,images,240,number_loaded,exp_nm);

inital_runoff = ~logical(sum(worms_nn_predicted>.75,2));

sess_diff = abs(raw_sess_data_aft_bw - raw_sess_data_bef_bw);

num_sess = length(median_norm_data2);

%pot_death = zeros(1,240);
censored_wells_runoff_var = zeros(1,240);
% go through every worm and calculate a running variance 

% B is the sorted array
% idx "sort index" that tells you where the sorted array came from
[B,idx]=sort(potential_lifespans_sess);


% for i = 1:240
for i = idx
    x = 1:num_sess;
    
    thisWorm = sess_diff(:,i);%.*(sess_diff(:,i)>0);

    pot_death = potential_lifespans_sess(i);
    if pot_death
        pot_death2 = pot_death;
        thisWorm(pot_death:end)=0;
    else
        thisWorm(1:end)=0;
        pot_death2 =1;
    end
    % calculate the first moving variance without filtering the data
    thisMoveVar1 = movvar(thisWorm,2);
    % find the index of the max
    [~,varIdx1] = max(thisMoveVar1);
    % calculate the second moving variance with 5 median filtering the data
    thisWorm_filt = medfilt1(thisWorm,10);
    thisMoveVar2 = movvar(thisWorm_filt,2);
    % find the index of the max
    [~,varIdx2] = max(thisMoveVar2);
% %     
% %     % % % % %                 THIS IS ONLY FOR CHECKING MANUALLY
% %     subplot(4,1,1)
% %     plot(x,thisMoveVar1/max(thisMoveVar1),'r',x,thisWorm/max(thisWorm),'b',varIdx1,thisMoveVar1(varIdx1)/max(thisMoveVar1),'r*',pot_death2,thisWorm(pot_death2)/max(thisWorm),'b*')
% %     title({['Worm: ' num2str(i)],['maxVar: ' num2str(varIdx1) ' - death: ' num2str(pot_death2)]})
% %     subplot(4,1,2)
% %     plot(sess_diff(:,i))
% %     title({'unprocessed raw data for worm', ['NN runoff: ' num2str(inital_runoff(i))]})
% %     subplot(4,1,3)
% %     imshow(large_images{i})
% %     title({'first couple sessions for worm',['Manual censor: ' num2str(censored_wells(i))]})
% %     subplot(4,1,4)
% %     plot(x,thisMoveVar2,'b',varIdx2,thisWorm_filt(varIdx2),'r*')
% %     title(['median filtered activity (blue) max variance (red)'])
    
    if pot_death2
        if pot_death<(num_sess/2)
            
            % if the worm max variance is too close to the death then
            % filter it as a runoff 
            if abs(varIdx1 - pot_death) <= 3
                censored_wells_runoff_var(i) = 1;
            else
                % similar process but using the running median filtered data
                if abs(varIdx2 - pot_death) <= 3
                    censored_wells_runoff_var(i) = 1;
                end
            end
        end
    end
end


censored_wells_runoff_nn = (inital_runoff');% | potential_runaway);

goodwells = nonzeros( (1:240).*(~censored_wells_runoff_nn));

save(char([data_storage '/processed_data/runoff_worms']),'censored_wells_runoff_var','censored_wells_runoff_nn');

disp([num2str(sum(censored_wells_runoff_var)) ' worms potentially ran away on ' exp_nm])




end

function [diff_imgs] = load_diff(data,number_loaded)

diff_dir = dir(fullfile([data '/raw_data/diff_imgs'],'*.png'));
[~,sort_idx,~] = natsort({diff_dir.name});
diff_dir = diff_dir(sort_idx);
diff_dir(ismember( {diff_dir.name}, {'.', '..'})) = [];
if number_loaded
    diff_imgs = cell(1,number_loaded);
else
    diff_imgs = cell(1,length(diff_dir));
end
for i = 1:length(diff_imgs)
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
    for i = ROI_nums
        s = regionprops(thisROI==i,'BoundingBox');
        xMin = ceil(s.BoundingBox(1));
        xMax = xMin + s.BoundingBox(3) - 1;
        yMin = ceil(s.BoundingBox(2));
        yMax = yMin + s.BoundingBox(4) - 1;
        images{i,j} = thisDiff(yMin:yMax,xMin:xMax);
    end
end
    
img_counter = 1;

daily_img_entire = cell(240*length(sess_nums),1);

for i = 1:240
        
    % isolate each worm
    this_worm_sess_imgs = images(i,:);
    
    % create a cell array for filtering
    this_worm_sess_imgs2 = cell(size(this_worm_sess_imgs));
    
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


function [nnResult_img,large_images] = nnRes_to_img(nnRes,images,num_wells,num_pics,exp_nm)

[rows,cols] = size(images);

% reshape the images array into a long array
if cols>1
    images = reshape(images',[num_wells*num_pics,1]);
else
    num_pics = rows/240;
end

parfor i = 1:length(images)
    
    this_nnRes = nnRes(i);
    
    this_nnRes(:,6:end,:)=[];
    
    if this_nnRes > .75
        images{i} = insertText(images{i},[150,10],this_nnRes,'BoxColor','green');
    else
        images{i} = insertText(images{i},[150,10],this_nnRes,'BoxColor','red');
    end
    
end
 
o=1;
large_images = cell(1,num_wells);
for i = 1:num_pics:length(images)
    large_images{o} = imtile(images(i:(i+num_pics-1)),'GridSize',[1,num_pics]);
    o=o+1;
end

nnResult_img = imtile(large_images,'GridSize',[length(images)/num_pics 1]);

nnResult_img = im2uint8(nnResult_img);

mkdir([pwd '/init_imgs'])
imwrite(nnResult_img,[pwd '/init_imgs/' exp_nm '_nn_result.png'])


end