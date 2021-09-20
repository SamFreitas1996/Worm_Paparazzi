% Differences from Create WormotelROIs:
% 
%       1. ROIs are CIRCLES, not SQUARES
%       2. Only 24 ROIs per plate
function [ref_img,ROI,N_wells,figs] = create24WellROIsInteractive(fimg,save_flag)

% Load reference image
if nargin < 1
    fimg = 'C:\Dropbox\Autogans Supporting Files\WWAnalyzer\ROI_Reference\All Roi types\Wormotel\2016-10-07 (00-30-00).png';
end

if nargin < 2
    save_flag = 1;
end

% Allow user to redo if they mess up
redo = 'Yes';

while strcmpi(redo,'Yes')
ref_img = imread(fimg);

% Calib points [row,col, x,y] out of the 12x20 setup from the top left
max_row = 4;
max_col = 6;

calib_points = [ 
                    1   1   nan     nan
                    4   1   nan     nan
                    1   6   nan     nan
                    4   6   nan     nan
                ];
            
    figure(1); clf, imagesc(ref_img); colormap gray; axis equal off;  
    set(gcf,'Position',[1          41        1920         964]);
    
    for i = 1:size(calib_points,1)
       
        title(sprintf('Click on well (r,c) = (%d,%d) from top left',calib_points(i,1),calib_points(i,2)),'FontSize',24);
        hold on;
        plot(calib_points(:,3),calib_points(:,4),'+r','LineWidth',2,'MarkerSize',20)
        [x,y] = ginput(1);
        calib_points(i,3) = x;
        calib_points(i,4) = y;
    end
            
% Generate interpolant fits            
    [fit_x,fit_y] = createFits(calib_points);

% Fill all well grid 

    % Create grids row/col positions of plates
    [plate_row_grid,plate_col_grid] = ndgrid(1:max_row,1:max_col);

    % Calculate interpolated / extrapolated X and Y coordinates
    plate_x_vals = fit_x(plate_row_grid,plate_col_grid);
    plate_y_vals = fit_y(plate_row_grid,plate_col_grid);  
    
% Overlay well locations
    figure(1); clf; imshow(ref_img); hold on;
    plot(plate_x_vals,plate_y_vals,'oc','MarkerSize',16,'LineWidth',2)
    
% Draw circular ROIs
    %R = 1384-1342; % Normal radius is 42
    R = mean(mean(diff(plate_x_vals,1,2)));
                
                % Radius of the full squares
    R = R*0.32; % Radius of shrunken squares
    
    wellposlist = [plate_x_vals(:),plate_y_vals(:),repmat(R,[numel(plate_x_vals),1])];
    
    BW = zeros(size(ref_img),'double');
    BW=insertShape(BW,'FilledCircle',wellposlist,'Color',[255 255 255]);
    BW = mean(BW,3)>0;
    
    
% Create labeled / numbered ROIs, should be 12*20 = 240 of them
    ROI = bwlabel(BW);
    
% Check number of ROIs
    N_wells = max(ROI(:));
    if(N_wells ~= max_row*max_col)
       redo = 'Yes';
       ui = errordlg(sprintf('ROI creation failed - image will be redone.\nExpected %d ROIs\nMade %d',12*20,N_wells));
       uiwait(ui);
       continue;
    end
    
% Sort ROIs
    [Labels_Sorted,old_order,new_order] = sortLabelsByCentroid(ROI,max_row,max_col);
    ROI = Labels_Sorted;
    figs{1} = getframe(gcf);
    
% Display ROIs    
    figure(2), clf, imagesc(ROI); colormap hot; colorbar; axis equal off;
    figs{2} = getframe(gcf);

    figure(3), clf, imagesc(ref_img); colormap gray; axis equal off; hold on;
    contour(ROI>0,1,'Color','r');
    set(gcf,'Position',[ 1          41        1920         964]);
    figs{3} = getframe(gcf);
    
% Extract relevant fig info
    for i = 1:numel(figs)
       figs{i} = figs{i}.cdata; 
    end
    
% Ask if user wants to redo
    redo = questdlg('Do you want to redo this image?','Redo?','Yes','No','No');
end 
    

end




function [fit_x,fit_y] = createFits(all_points)

% Clear the last warning
    lastwarn('');

% Second try - use interpolant fits. Treat fit warnings as errors and require good r^2 values.
    [fit_x,gof_x] = createInterpolant2DFit(all_points(:,1),all_points(:,2),all_points(:,3), [' | CNC X'],1);
        set(gcf,'Position',[25    61   560   420]);

    [fit_y,gof_y] = createInterpolant2DFit(all_points(:,1),all_points(:,2),all_points(:,4), [' | CNC Y'],2);
        set(gcf,'Position',[608    64   560   420]);


end