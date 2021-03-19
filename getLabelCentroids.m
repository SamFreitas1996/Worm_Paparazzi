% getLabelCentroids.m
% anthony Fouad
% 
% Helper function for getLabelRowCol and sortLabelsByCentroid - find the
% centroids of all labels in the image and create an idealized grid


function [centroids, rowvals, colvals, max_label] = getLabelCentroids(Labels,N_rows,N_cols)

% Verify that the labeled image fits the requested size.
    Labels = uint8(Labels);
    max_label = max(Labels(:));

    if max_label ~= N_rows * N_cols
       error('Supplied labels image has %d Regions, but the requested sort size is %d x %d = %d Regions\n',max_label,N_rows,N_cols,N_rows*N_cols)
    end
    
% Find the centroids of each object
centroids = nan(max_label,2);
for n = 1:max_label
    this_roi = Labels == n;
    stats = regionprops(this_roi,'Centroid');
    centroids(n,:) = stats.Centroid;
end

% Find top-left centroid
idx = dsearchn(centroids,[0 0]);
top_left = centroids(idx,:);

% Find bottom-right centroid
idx = dsearchn(centroids,[999999 999999]);
bottom_right = centroids(idx,:);

% Create an idealized grid
[rowvals,colvals] = ndgrid(linspace(top_left(2),bottom_right(2),N_rows),linspace(top_left(1),bottom_right(1),N_cols));

end