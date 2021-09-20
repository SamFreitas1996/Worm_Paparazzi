close all
csv_path = "C:\Users\Lab PC\Documents\pytorch_testing\results";
csv_dir = dir(fullfile(csv_path,'*.csv'));

imgs_path = "C:\Users\Lab PC\Documents\pytorch_testing\temp_imgs";
imgs_dir = dir(fullfile(imgs_path,'*.png'));

se = strel('disk',5);
first_img = imread(fullfile(imgs_dir(1).folder,imgs_dir(1).name));

[h,w] = size(first_img);

for i = 1:length(imgs_dir)
    
    this_img = imread(fullfile(imgs_dir(i).folder,imgs_dir(i).name));
    
    this_result = table2array(readtable(fullfile(csv_dir(i).folder,csv_dir(i).name)));
    this_data = this_result(:,1:4);
        
    % if there are less than 240 data points 
    if ~(length(this_data)>=240)
        [ROI_grid] = try_grid_fit(this_data(:,1),this_data(:,2),w,h);
        
        x = ROI_grid(:,1);
        y = ROI_grid(:,2);
        
    elseif (length(this_data)>240)
        this_data2 = this_data;
        
        while(~isequal(length(this_data2),240))
            
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
        
        end
                
        x = this_data2(:,1);
        y = this_data2(:,2);
    else        
        x = this_data(:,1);
        y = this_data(:,2);
        
    end
    
    [thisROI] = gen_roi_from_data(x,y,w,h);
    

    figure;
    imshow(this_img.*uint8(thisROI>0))
    title(i)
    
    hold on 
    plot(x,y,'r*')
    hold off
    
end


function [thisROI] = gen_roi_from_data(xdata,ydata,w,h)

thisROI = zeros(h,w);

[xdata_temp,sort_idx] = sort(xdata);
ydata_temp = ydata(sort_idx);

[~,locs]=findpeaks(diff(xdata_temp),'threshold',15);
locs2 = [1; locs; length(xdata_temp)];

for j = 1:length(locs2)-1
    if j == 1
        cols{j} = [xdata_temp(1:locs2(2)),ydata_temp(1:locs2(2))];
    else
        cols{j} = [xdata_temp(locs2(j)+1:locs2(j+1)),ydata_temp(locs2(j)+1:locs2(j+1))];
    end
end

k=1;
for i = 1:length(cols)
    
    this_col = cols{i};
    
    [~,sort_idx] = sort(this_col(:,2));
    
    this_col = this_col(sort_idx,:);
    
    for j = 1:length(this_col)
        
        x_box = round(this_col(j,1)-102:this_col(j,1)+102);
        y_box = round(this_col(j,2)-102:this_col(j,2)+102);
        
        thisROI(y_box,x_box) = k;
        k=k+1;
    end
    
end

end

function [ROI_grid] = try_grid_fit(xdata,ydata,cc,rr)

% sort the data with respect to x
[xdata_temp,sort_idx] = sort(xdata);
ydata_temp = ydata(sort_idx);

% find where the data has columns
[pks,locs]=findpeaks(diff(xdata_temp),'threshold',15);
locs2 = [1; locs; length(xdata_temp)];

for j = 1:length(locs2)-1
    if j == 1
        cols{j} = [xdata_temp(1:locs2(2)),ydata_temp(1:locs2(2))];
    else
        cols{j} = [xdata_temp(locs2(j)+1:locs2(j+1)),ydata_temp(locs2(j)+1:locs2(j+1))];
    end
end

% sort the data with respect to x
[ydata_temp,sort_idx] = sort(ydata);
xdata_temp = xdata(sort_idx);

% find different rows
[pks,locs]=findpeaks(abs(diff(ydata_temp)),'threshold',50);
locs2 = [1; locs; length(ydata_temp)];

% isolate each row
for j = 1:length(locs2)-1
    if j == 1
        rows{j} = [xdata_temp(1:locs2(2)),ydata_temp(1:locs2(2))];
    else
        rows{j} = [xdata_temp(locs2(j)+1:locs2(j+1)),ydata_temp(locs2(j)+1:locs2(j+1))];
    end
end


for j = 1:length(rows)
    x = rows{j}(:,1);
    y = rows{j}(:,2);
    [x,sort_idx] = sort(x,'ascend');
    y = medfilt1(y(sort_idx),3);
    
    p = polyfit(x,y,2);
    %     disp(p(1:2))
    
    if abs(p(2))> 0.02
        p = polyfit(x(2:end-1),y(2:end-1),1);
    end
    
    x2{j} = 0:cc;
    y2{j} = polyval(p,x2{j});
    
%     plot(x2{j},y2{j})
end

for j = 1:length(cols)
    y_flip = cols{j}(:,1);
    x_flip = cols{j}(:,2);
    [x_flip,sort_idx] = sort(x_flip,'ascend');
    y_flip = medfilt1(y_flip(sort_idx),3);
    
    p = polyfit(x_flip,y_flip,2);
    if abs(p(2)) > 0.025
        p = polyfit(x_flip(2:end-1),y_flip(2:end-1),1);
    end
    
    y3{j} = 0:rr;
    x3{j} = polyval(p,y3{j});
    
%     plot(x3{j},y3{j})
end

ROI_grid = zeros(240,2);
o=1;
for j = 1:length(x3) % columns
    
    for k = 1:length(x2) % rows
        
        [x0,y0] = intersections(x3{j},y3{j},x2{k},y2{k});
        
        ROI_grid(o,:) = [x0,y0];
        o=o+1;
    end
    
end

plot(ROI_grid(:,1),ROI_grid(:,2),'bo')

end




