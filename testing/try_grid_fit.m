function [ROI_grid] = try_grid_fit(xdata,ydata,cc,rr)

% sort the data with respect to x
[xdata_temp,sort_idx] = sort(xdata);
ydata_temp = ydata(sort_idx);

% find where the data has columns
[~,locs]=findpeaks(diff(xdata_temp),'threshold',15);
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
[~,locs]=findpeaks(abs(diff(ydata_temp)),'threshold',50);
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

% plot(ROI_grid(:,1),ROI_grid(:,2),'bo')

end
