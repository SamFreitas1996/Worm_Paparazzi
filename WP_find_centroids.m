%WP find centroids 

function [centroids] = WP_find_centroids(temp_img,thisROI)

BW = temp_img>0;

centroids = zeros(max(max(thisROI)),2);
% for each ROI
for i = max(max(thisROI)):-1:1
    % isolate the ROI
    s=regionprops(thisROI==i,'BoundingBox');
    
    xMin = ceil(s.BoundingBox(1));
    xMax = xMin + s.BoundingBox(3) - 1;
    yMin = ceil(s.BoundingBox(2));
    yMax = yMin + s.BoundingBox(4) - 1;
    
    % Then this removes all the wells from large images
    % and removes everything that isnt the wells
    
    s2 = regionprops( BW(yMin:yMax,xMin:xMax),'basic');
    if ~isempty(s2)
        if length(s2)>1
            [~,idx] = max([s2.Area]);
            centroids(i,:) = s2(idx).Centroid(:);
        else
            centroids(i,:) = s2.Centroid(:);
        end
    end
    
end


end


