function [fixed_ROI] = attempt_to_fix_ROI(first_good_ROI,first_good_sess,this_sess,this_data)

% scrape the data
xdata = this_data(:,1);
ydata = this_data(:,2);
% sort data
[xdata_temp,sort_idx] = sort(xdata);
ydata_temp = ydata(sort_idx);
% isolate columns of data
[~,locs]=findpeaks(diff(xdata_temp),'threshold',15);
locs2 = [1; locs; length(xdata_temp)];
% if the data is more than 240 cases
if (length(this_data)>240)
    this_data2 = this_data;
    % find the widths of the data square
    ROI_width_data = this_data(:,3:4);
    % if the data isnt a good enough width get rid of it
    k=1;
    for j = 1:length(ROI_width_data)
        if sum(ROI_width_data(j,:))<370
            bad_idx(k) = j;
            k=k+1;
        end
    end
    
    this_data2(bad_idx,:) = [];
    
    % while there are more than 240 data points 
    % iterate through and get rid of any distance too small 
%     while(~isequal(length(this_data2),240))
        
    for j = 1:length(this_data2)
        distances = sqrt(sum(bsxfun(@minus, this_data2, this_data2(j,:)).^2,2));
        distances(j) = 1000;
        if sum(distances<200)

            this_idx = find(distances<200,1,'first');

            this_data2(j,:) = mean([this_data2(j,:);this_data2(this_idx,:)]);
            this_data2(this_idx,:) = [];

            if length(this_data2) == 240
                break
            end

        end

    end
        
%     end
    
    xdata = this_data2(:,1);
    ydata = this_data2(:,2);
    
    [xdata_temp,sort_idx] = sort(xdata);
    ydata_temp = ydata(sort_idx);
    
    [~,locs]=findpeaks(diff(xdata_temp),'threshold',15);
    locs2 = [1; locs; length(xdata_temp)];
end
% sort into columns 
for j = 1:length(locs2)-1
    if j == 1
        cols{j} = [xdata_temp(1:locs2(2)),ydata_temp(1:locs2(2))];
    else
        cols{j} = [xdata_temp(locs2(j)+1:locs2(j+1)),ydata_temp(locs2(j)+1:locs2(j+1))];
    end
end
% create columns going from the bottom to the top
% generally the robot is overshooting not undershooting 
% undershooting also needs to be fixed
thisROI = zeros(size(first_good_ROI));
for i = 1:length(cols)
    
    this_col = cols{i};
    
    [~,sort_idx] = sort(this_col(:,2));
    
    this_col = this_col(sort_idx,:);
    
    k = 12*i;
    
    for j = length(this_col):-1:1
        
        try
            x_box = round(this_col(j,1)-102:this_col(j,1)+102);
            y_box = round(this_col(j,2)-102:this_col(j,2)+102);
            
            thisROI(y_box,x_box) = k;
            
            k=k-1;

        catch
            
        end

    end
    
end




fixed_ROI = thisROI;


% 
% bad_ROI = zeros(size(first_good_ROI));
% 
% bad_ROI(1:max(y),1:max(x)) = 1;
% 
% bad_sess_data = zeros(size(first_good_ROI));
% bad_sess_data(1:max(y),1:max(x)) = this_sess(1:max(y),1:max(x));
% 
% fixed_ROI = zeros(size(first_good_ROI));
% 
% se=strel('disk',40,4);
% 
% maskA=(imclose(first_good_ROI,se)>0);
% movingImgA=maskA.*double(first_good_sess);
% 
% s=regionprops(movingImgA>0,'basic');
% 
% xMin = ceil(s.BoundingBox(1));
% xMax = xMin + s.BoundingBox(3) - 1;
% yMin = ceil(s.BoundingBox(2));
% yMax = yMin + s.BoundingBox(4) - 1;
% 
% % Then this removes all the wells from large images
% % and removes everything that isnt the wells
% cutImg=first_good_sess(yMin:yMax,xMin:xMax);
% 
% try
%     c = normxcorr2(cutImg,bad_sess_data);
% catch
%     c = normxcorr2(cutImg,bad_sess_data);
% end
% [ypeak,xpeak] = find(c==max(c(:)));
% yoffSet = ypeak-size(cutImg,1);
% xoffSet = xpeak-size(cutImg,2);
% 
% ROIA = fixed_ROI;
% % centers the most relevant ROIs on the actual
% % images and creates a new custom ROI from that
% % session
% ROIA(yoffSet:(yoffSet+size(cutImg,1)-1),xoffSet:(xoffSet+size(cutImg,2)-1))=...
%     first_good_ROI(yMin:yMax,xMin:xMax);




end