% sortLabelsByCentroid
% Anthony Fouad
% 
% Re-sort the outputs of bwlabel so that ROIs are in order of 1-24 (for
% example) from the top left corner, columnwise down, into the specified
% rows and columns.
%
% NOTE: ASSUMES ROI CENTROIDS ARE APPROXIMATELY SPACED AS A RECTANGULAR
% GRID, LIKE A 24 WELL PLATE. 

function [Labels_Sorted,old_order,new_order] = sortLabelsByCentroid(Labels,N_rows,N_cols,show_plots,AXES)

% Handle inputs
    if nargin < 4; show_plots = 1; end
    if nargin < 5; AXES = []; end
        
% Get the centroids and an idealized grid
[centroids, rowvals, colvals, max_label] = getLabelCentroids(Labels,N_rows,N_cols);
colvals_list = colvals(:);
rowvals_list = rowvals(:);

% Create blank new image
Labels_Sorted = zeros(size(Labels),'uint8');
    
% Find the idealized centroid matching each real centroid

old_order = nan([1,N_rows*N_cols]);
new_order = nan([1,N_rows*N_cols]);

for i = 1:max_label
   
    % Find index of idealized centroid closely matching this centroid
    this_centroid = centroids(i,:);
    idx = dsearchn([colvals_list,rowvals_list],this_centroid);
    
    % Draw this ROI on the output image
    Labels_Sorted(Labels==i) = idx;
    
    % Keep track of order of the original Labels
    old_order(i) = Labels(round(rowvals_list(i)),round(colvals_list(i)));
    new_order(i) = i;
    
end

% Show plots if requested
if show_plots
    if ~isempty(AXES)
        axes(AXES);
    else
        figure(3), clf, 
    end

    imagesc(Labels); hold on; colormap gray; 
    plot(colvals(:),rowvals(:),'-og'); 
    plot(centroids(:,1),centroids(:,2),':xr')
end
end