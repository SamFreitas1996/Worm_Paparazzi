

function experiment_divisions_manual(exp_dir,newROIs,data_storage,exp_nm)


day_to_load=round(length(exp_dir));
temp_dirstep=dir([exp_dir(day_to_load).folder '/' exp_dir(day_to_load).name]);
temp_dirstep(ismember( {temp_dirstep.name}, {'.', '..'})) = [];  %remove . and ..

first_image = imread([temp_dirstep(1).folder '/' temp_dirstep(15).name]);

ROI_overlay=newROIs{day_to_load,1};



redo = 'Yes';
while isequal(redo,'Yes')
    clearvars -except ROI_overlay first_image exp_dir data_storage exp_nm newROIs
    counter = 1;
    
    f = msgbox(['Please select the first ROI for ' exp_nm]);
    set(f,'WindowStyle','modal')
    pause(1.5)
    [~,rect] = imcrop(first_image);
    try
    close(f)
    catch
    end
    
    rect = round(rect);
    this_crop = ROI_overlay(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
    
    selected_rois{1} = double(unique(nonzeros(this_crop(:))));
    red_rois = zeros(size(ROI_overlay));
    for i = 1:length(selected_rois{1})
        red_rois = red_rois + (ROI_overlay==selected_rois{1}(i));
    end
    new_label_rois = red_rois;
    R = first_image + uint8(20*counter*red_rois);
    G_B = first_image;
    rgbImage = cat(3, R, G_B, G_B);
    imshow(rgbImage)
    
    div_names{counter} = inputdlg(['What division was this ROI selection? -- for ' exp_nm ' division: ' num2str(counter)]);
    
    cont = 'Yes';
    while isequal(cont,'Yes')
        
        counter = counter + 1;
        
        cont = questdlg({'Is there another ROI to select? "Yes"',...
            'If there is no further ROI select "No"',...
            'If so draw rectange touching all the specific ROIs and double click it'},'ROI?','Yes','No','Yes');
        if isequal(cont,'Yes')
            [~,rect] = imcrop(rgbImage);
            rect = round(rect);
            this_crop = ROI_overlay(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
            selected_rois{counter} = double(unique(nonzeros(this_crop(:))));
            red_rois = zeros(size(ROI_overlay));
            for i = 1:length(selected_rois{counter})
                red_rois = red_rois + (ROI_overlay==selected_rois{counter}(i));
            end
            new_label_rois = new_label_rois + (red_rois*counter);
            R = R + uint8(20*counter*red_rois);
            
            rgbImage = cat(3, R, G_B, G_B);
            imshow(rgbImage)
            
            div_names{counter} = inputdlg(['What division was this ROI selection? -- for ' exp_nm ' division: ' num2str(counter)]);
            
        else
            close all
        end
        
        
        
    end
    
    rgbImage = label2rgb(new_label_rois);
    
    for i = 1:length(div_names)
        
        this_blob = imgaussfilt(double(100* (new_label_rois==i)),10);
        
        measurements = regionprops(this_blob>0, 'Centroid');
        box = measurements.Centroid;
        
        text_box = [char(div_names{i}) ' - ' num2str(length(selected_rois{i})) ' wells'];
        
        rgbImage = insertText(rgbImage, round([box(1),box(2)]), text_box,'FontSize',100);
        
    end
    
    imshow(rgbImage)
    
    redo = questdlg({'Does this ROI need to be redone? Please double check',...
        'If it does then this script will repeat'},'ROI?','Yes','No','Yes');
    
    % check for 240 locations
    num_roi_checker = 1:240;
    num_roi = [];
    for i = 1:length(div_names)
        num_roi = [num_roi;selected_rois{i}];
    end
    num_roi = sort(num_roi)';
    
    if isequal(length(num_roi),length(num_roi_checker))
        if sum(num_roi-num_roi_checker)
            redo = 'Yes';
            disp('Incorrect number of Wells selected, check overlap or missing values');
        end
        
    else
        redo = 'Yes';
        disp('Incorrect number of Wells selected, check overlap or missing values');
    end
end

output = cell(240+1,length(div_names));
for i = 1:length(div_names)
    output(1,i) = {char(div_names{i})};
    for j = 1:length(selected_rois{i})
        output(j+1,i) = {selected_rois{i}(j)};
    end
end


%%%%%%%%%%%%%%%%output
%%%%%% location on plate, dosage, strain,

T = cell2table(output(2:end,:),'VariableNames',output(1,:));
writetable(T,[data_storage 'divisions.csv'])



end