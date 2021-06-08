function experiment_divisions_manual2(exp_dir,newROIs,data_storage,exp_nm,final_data_export_path,full_exp_name)
% load in peaks data
save_peaks_name = [data_storage 'raw_data/peaks.mat'];
load(char(save_peaks_name))
% find session numbers
k=0;
for i = 1:length(nonzeros(sum(locs,2)))
    for j = 1:length(nonzeros(sum(locs)))
        if ~isempty(newROIs{i,j})
            k=k+1;
            sess_nums(i,j) = k;
        end
    end
end

% choose the first day to load
day_to_load=round(length(exp_dir));
temp_dirstep=dir([exp_dir(day_to_load).folder '/' exp_dir(day_to_load).name]);
temp_dirstep(ismember( {temp_dirstep.name}, {'.', '..'})) = [];  %remove . and ..

first_image = imread([temp_dirstep(1).folder '/' temp_dirstep(15).name]);

ROI_overlay=newROIs{day_to_load,1};

unique_overlay_template = [0:1:240]';
unique_overlay_vector = unique(ROI_overlay);
if ~isequal(unique_overlay_vector,unique_overlay_template)
    disp('bad session chosen, picking a new one')
    
    first_column_sessions = sess_nums(:,1);
    
    for i = length(first_column_sessions):-1:1
        [a,b] = find(first_column_sessions == first_column_sessions(i));
        
        unique_overlay_vector = unique(newROIs{a,b});
        
        if isequal(unique_overlay_vector,unique_overlay_template)
            disp(['Session: ' num2str(first_column_sessions(i)) ' found to be good']);
            ROI_overlay=newROIs{i,1};
            
            day_to_load = i;
            
            temp_dirstep=dir([exp_dir(day_to_load).folder '/' exp_dir(day_to_load).name]);
            temp_dirstep(ismember( {temp_dirstep.name}, {'.', '..'})) = [];  %remove . and ..
            
            first_image = imread([temp_dirstep(1).folder '/' temp_dirstep(15).name]);
            
            break
        end
        
    end
    
end

clear unique_overlay_template unique_overlay_vector first_sessions a b first_sessions

output_cells = cell(240,3);
header = ["Well Location","Dosage","Strain"];

for i = 1:240
    output_cells{i,1} = i;
end

redo = 'Yes';
while isequal(redo,'Yes')
    dosage_counter = 1;
    
    % create the first dosage
    f = msgbox(['Please select the first Dosage for ' exp_nm]);
    set(f,'WindowStyle','modal')
    pause(1.5)
    % crop the image for just the selected dosages
    [~,rect] = imcrop(first_image);
    try
        close(f)
    catch
    end
    % take the first crop and overlay it onto the ROIs
    rect = round(rect);
    this_crop = ROI_overlay(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
    
    % isolate each ROI number
    selected_rois_dosages{1} = double(unique(nonzeros(this_crop(:))));
    
    % create the overlay that the user sees
    red_rois = zeros(size(ROI_overlay));
    for i = 1:length(selected_rois_dosages{1})
        red_rois = red_rois + (ROI_overlay==selected_rois_dosages{1}(i));
    end
    new_label_rois = red_rois;
    R = first_image + uint8(20*dosage_counter*red_rois);
    G_B = first_image;
    rgbImage = cat(3, R, G_B, G_B);
    imshow(rgbImage)
    
    % Ask for the dosage name
    dosage_names{dosage_counter} = inputdlg(['What division was this Dosage selection? -- for ' exp_nm ' division: ' num2str(dosage_counter)]);
    
    % 
    for i = 1:length(selected_rois_dosages{1})
        output_cells{selected_rois_dosages{1}(i),2} = dosage_names{dosage_counter};
    end
    
    
    cont = 'Yes';
    while isequal(cont,'Yes')
        
        dosage_counter = dosage_counter + 1;
        
        cont = questdlg({'Is there another ROI to select? "Yes"',...
            'If there is no further ROI select "No"',...
            'If so draw rectange touching all the specific ROIs and double click it'},'ROI?','Yes','No','Yes');
        if isequal(cont,'Yes')
            [~,rect] = imcrop(rgbImage);
            rect = round(rect);
            this_crop = ROI_overlay(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
            selected_rois_dosages{dosage_counter} = double(unique(nonzeros(this_crop(:))));
            red_rois = zeros(size(ROI_overlay));
            for i = 1:length(selected_rois_dosages{dosage_counter})
                red_rois = red_rois + (ROI_overlay==selected_rois_dosages{dosage_counter}(i));
            end
            new_label_rois = new_label_rois + (red_rois*dosage_counter);
            R = R + uint8(20*dosage_counter*red_rois);
            
            rgbImage = cat(3, R, G_B, G_B);
            imshow(rgbImage)
            
            dosage_names{dosage_counter} = inputdlg(['What division was this Dosage selection? -- for ' exp_nm ' division: ' num2str(dosage_counter)]);
            
            try
                for i = 1:length(selected_rois_dosages{dosage_counter})
                    output_cells{selected_rois_dosages{dosage_counter}(i),2} = dosage_names{dosage_counter};
                end
            catch
                cont = 'No';
                redo = 'Yes';
                
                disp('something went wrong in creation of the division, redo suggested')
                
                break
            end
            
        else
            close all
        end
        
        
        
    end
    
    strain_counter = 1;
    
    % create the first dosage
    f = msgbox(['Please select the first Strain for ' exp_nm]);
    set(f,'WindowStyle','modal')
    pause(1.5)
    % crop the image for just the selected dosages
    [~,rect] = imcrop(rgbImage);
    try
        close(f)
    catch
    end
    % take the first crop and overlay it onto the ROIs
    rect = round(rect);
    this_crop = ROI_overlay(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
    
    % isolate each ROI number
    selected_rois_strains{1} = double(unique(nonzeros(this_crop(:))));
    
    % create the overlay that the user sees
    blue_rois = zeros(size(ROI_overlay));
    for i = 1:length(selected_rois_strains{1})
        blue_rois = blue_rois + (ROI_overlay==selected_rois_strains{1}(i));
    end
    new_label_rois = blue_rois;
    R = rgbImage(:,:,1);
    G = rgbImage(:,:,2);
    B = rgbImage(:,:,3) + uint8(20*strain_counter*blue_rois);
    rgbImage = cat(3, R, G, B);
    imshow(rgbImage)
    
    % Ask for the dosage name
    strain_names{strain_counter} = inputdlg(['What division was this Strain selection? -- for ' exp_nm ' division: ' num2str(dosage_counter)]);
    
    % 
    for i = 1:length(selected_rois_strains{1})
        output_cells{selected_rois_strains{1}(i),3} = strain_names{strain_counter};
    end
    
    
    cont = 'Yes';
    while isequal(cont,'Yes')
        
        strain_counter = strain_counter + 1;
        
        cont = questdlg({'Is there another Strian to select? "Yes"',...
            'If there is no further Strain select "No"',...
            'If so draw rectange touching all the specific ROIs and double click it'},'ROI?','Yes','No','Yes');
        if isequal(cont,'Yes')
            [~,rect] = imcrop(rgbImage);
            rect = round(rect);
            this_crop = ROI_overlay(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
            selected_rois_strains{strain_counter} = double(unique(nonzeros(this_crop(:))));
            blue_rois = zeros(size(ROI_overlay));
            for i = 1:length(selected_rois_strains{strain_counter})
                blue_rois = blue_rois + (ROI_overlay==selected_rois_strains{strain_counter}(i));
            end
            new_label_rois = new_label_rois + (blue_rois*strain_counter);
            R = rgbImage(:,:,1);
            G = rgbImage(:,:,2);
            B = rgbImage(:,:,3) + uint8(20*strain_counter*blue_rois);
            rgbImage = cat(3, R, G, B);
            imshow(rgbImage)
            
            strain_names{strain_counter} = inputdlg(['What division was this Strain selection? -- for ' exp_nm ' division: ' num2str(dosage_counter)]);
            try
                for i = 1:length(selected_rois_strains{strain_counter})
                    output_cells{selected_rois_strains{strain_counter}(i),3} = strain_names{strain_counter};
                end
            catch
                cont = 'No';
                redo = 'Yes';
                
                disp('something went wrong in creation of the division, redo suggested')
                break
            end
            
        else
            close all
        end
        
        
        
    end
    
%     dosage_isolation = string(output_cells(:,2));
%     strain_isolation = string(output_cells(:,3));
%     blob_counter = 1;
%     new_label_rois = zeros(size(ROI_overlay));
%     for i = 1:length(dosage_names)
%         for j = 1:length(strain_names)
%             dos_temp = zeros(size(dosage_isolation));
%             str_temp = zeros(size(strain_isolation));
%             dos_temp(dosage_isolation==dosage_names{i}) = 1;
%             str_temp(strain_isolation==strain_names{j}) = 1;
%             
%             this_blob = nonzeros((1:240)'.*str_temp.*dos_temp);
%             
%             for k = 1:length(this_blob)
%                 new_label_rois = new_label_rois + blob_counter*(ROI_overlay==this_blob(k));
%             end
%             
%             wells_per_blob(blob_counter) = length(this_blob);
%             
%             blob_counter = blob_counter+1;
%             
%         end
%     end
    
    output_cells(:,4) = {','};
    
    div_iso = strings([length(output_cells),1]);
    
    for i = 1:length(output_cells)
        div_iso(i) = string(strcat(output_cells{i,[2,4,3]}));
    end
    
    unique_divisions = unique(div_iso);
    roi_divisions = cell([1,length(unique_divisions)]);
    for i = 1:length(unique_divisions)
        roi_divisions{i} = find(div_iso==unique_divisions(i));
    end
    
    new_label_rois2 = zeros(size(new_label_rois));
    for i = 1:length(roi_divisions)
        for j = 1:length(roi_divisions{i})
            
            new_label_rois2 = new_label_rois2 + i*double(ROI_overlay==roi_divisions{i}(j));
            
        end
    end
    
    rgbImage = label2rgb(new_label_rois2);
    
    blob_counter = 1;
    blob_id = unique(nonzeros(new_label_rois2));
    for i = 1:length(unique_divisions)
        this_blob = imgaussfilt(double(100* (new_label_rois2==blob_id(blob_counter))),10);
        measurements = regionprops(this_blob>0, 'Centroid');
        box = measurements.Centroid;
        this_name = char(unique_divisions(i));
        num_wells = length(roi_divisions{i});
        rgbImage = insertText(rgbImage, round([box(1)-200,box(2)]), this_name,'FontSize',100);
        rgbImage = insertText(rgbImage, round([box(1)-200,box(2)+200]), num_wells,'FontSize',100);
        
        blob_counter = blob_counter + 1;
    end
    
%     for i = 1:length(dosage_names)
%         for j = 1:length(strain_names)
%             
%             this_blob = imgaussfilt(double(100* (new_label_rois==blob_id(blob_counter))),10);
%             
%             measurements = regionprops(this_blob>0, 'Centroid');
%             box = measurements.Centroid;
%             
%             this_name = [char(dosage_names{i}) ',' char(strain_names{j})];
%             
%             num_wells = [num2str(wells_per_blob(blob_counter)) ' wells'];
%             
% %             text_box = [this_name ' - ' num2str(length(selected_rois_dosages{i})) ' wells'];
%             
%             rgbImage = insertText(rgbImage, round([box(1)-200,box(2)]), this_name,'FontSize',100);
%             rgbImage = insertText(rgbImage, round([box(1)-200,box(2)+200]), num_wells,'FontSize',100);
%             
%             blob_counter= blob_counter+1;
%             
%         end
%     end
    
    imshow(rgbImage)
    
    redo = questdlg({'Does this ROI need to be redone? Please double check',...
        'If it does then this script will repeat'},'ROI?','Yes','No','Yes');
    
    % check for 240 locations
    num_roi_checker = 1:240;
    num_roi = [];
    for i = 1:length(dosage_names)
        num_roi = [num_roi;selected_rois_dosages{i}];
    end
    num_roi = unique(sort(num_roi))';
    
    if isequal(length(num_roi),length(num_roi_checker))
        if sum(num_roi-num_roi_checker)
            redo = 'Yes';
            disp('Incorrect number of Dosage Wells selected, check overlap or missing values');
        end
        
    else
        redo = 'Yes';
        disp('Incorrect number of Dosage Wells selected, check overlap or missing values');
    end
    num_roi_checker = 1:240;
    num_roi = [];
    for i = 1:length(strain_names)
        num_roi = [num_roi;selected_rois_strains{i}];
    end
    num_roi = unique(sort(num_roi))';
    
    if isequal(length(num_roi),length(num_roi_checker))
        if sum(num_roi-num_roi_checker)
            redo = 'Yes';
            disp('Incorrect number of Strain Wells selected, check overlap or missing values');
        end
        
    else
        redo = 'Yes';
        disp('Incorrect number of Strain Wells selected, check overlap or missing values');
    end
end



%%%%%%%%%%%%%%%%output
%%%%%% location on plate, dosage, strain,

% make final output directory
mkdir(fullfile(final_data_export_path,full_exp_name))
mkdir(fullfile(final_data_export_path,full_exp_name,'divisions'))

out_path = fullfile(final_data_export_path,full_exp_name,'divisions');
% write division images
imwrite(rgbImage,[data_storage 'divisions.png']);
imwrite(rgbImage,fullfile(out_path,[exp_nm '_divisions_visual.png']))

T = cell2table(output_cells(:,1:3),'VariableNames',header);
% wirte division tables
writetable(T,[data_storage 'divisions.csv'])
writetable(T,fullfile(out_path,[exp_nm '_divisions.csv']))

close all

end