function [thisROI,potential_bad] = gen_roi_from_nn_data(xdata,ydata,w,h)

thisROI = zeros(h,w);

potential_bad = 0;

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
double_break = 0;
for i = 1:length(cols)
    
    this_col = cols{i};
    
    [~,sort_idx] = sort(this_col(:,2));
    
    this_col = this_col(sort_idx,:);
    
    for j = 1:length(this_col)
        
        x_box = round(this_col(j,1)-102:this_col(j,1)+102);
        y_box = round(this_col(j,2)-102:this_col(j,2)+102);
        
        if y_box(1) < 1
            y_box = 1:205;
            potential_bad = 1;
            double_break = 1;
            break
        end
        
        if x_box(1) < 1
            x_box = 1:205;
            potential_bad = 1;
            double_break = 1;
            break
        end
        
        if y_box(end) > h 
            y_box = h-205:h;
            potential_bad = 1;
            double_break = 1;
            break
        end
        
        if x_box(end) > w
            x_box = w-205:w;
            potential_bad = 1;
            double_break = 1;
            break
        end
        
        thisROI(y_box,x_box) = k;
        k=k+1;
    end
    
    if double_break
        thisROI = zeros(h,w);
        break
    end
    
end

end