% Day_runoff



img_counter = 1;

daily_img_entire = cell(240*length(sess_nums),1);

for i = 1:240
    
    disp(i)
    
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
    
    for j = 1:length(daily_img)
        daily_img_entire{img_counter} = daily_img{j};
        img_counter = img_counter+1;
    end
    
    
end


parfor j = 1:length(daily_img_entire)
    imwrite(daily_img_entire{j},[temp_imgs_path '/' num2str(j) '.jpg']);
end

