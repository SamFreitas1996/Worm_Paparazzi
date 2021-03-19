function [thisROI] = gen_roi_from_nn_data(xdata,ydata,w,h)

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