% MAKE SURE THAT THIS IS IN THE CORRECT DIRECTORY BEFORE USAGE NOT TO BE
% USED ON THE SERVER

warning('off','all')

prompt = ['IS ' pwd ' ON THE LOCAL MACHINE AND NOT SERVER'];
dlgtitle = 'PROMPT';

answer = inputdlg(prompt,dlgtitle);

if isequal(answer{1},'yes') || isequal(answer{1},'y') || isequal(answer{1},'Yes')
    
    working_dir = uigetdir('/groups/sutphin');
    
    files = dir(working_dir);
    dirFlags = [files.isdir];
    
    not_dirFlags = ~dirFlags;
    not_dirFlags_idx = nonzeros((1:length(not_dirFlags)).*(not_dirFlags));
    
    for i = 1:length(not_dirFlags_idx)
        disp(['Remove ' files(not_dirFlags_idx(i)).name])
        delete(fullfile(files(not_dirFlags_idx(i)).folder,files(not_dirFlags_idx(i)).name))
        
    end
    
    folders = files(dirFlags);
    folders(ismember( {folders.name}, {'.', '..'})) = [];  %remove . and ..
    
    num_bytes_to_keep = 1000000; % one million bites is one MB
    
    X_days_ago = datetime - caldays(num_bytes_to_keep);
        
    for i = 1:length(folders)
        
        this_folder = folders(i).name;
        disp(['Running for ' this_folder])
        
        % find all folders in a sub folder
        temp_dir_step_exp = dir(fullfile(folders(i).folder,folders(i).name));
        temp_dir_step_exp(ismember( {temp_dir_step_exp.name}, {'.', '..'})) = [];  %remove . and ..
        
        % delete .DS_store its a mac thing idk
        try
            delete(fullfile(temp_dir_step_exp(1).folder,'.DS_Store'));
            rmdir(fullfile(temp_dir_step_exp(1).folder,'@eaDir'),'s')
        catch
            
        end
        
        % remake the folder struct 
        temp_dir_step_exp = dir(fullfile(folders(i).folder,folders(i).name));
        temp_dir_step_exp(ismember( {temp_dir_step_exp.name}, {'.', '..'})) = [];  %remove . and ..
                
        % find all the dirs
        dirFlags_step = [temp_dir_step_exp.isdir];
        
        % get the step
        temp_dir_step_exp = temp_dir_step_exp(dirFlags_step);
        
        % go through all files and delete any under 1MB
        for j = 1:length(temp_dir_step_exp)
            try
                temp_dir_step_plate = dir(fullfile(temp_dir_step_exp(j).folder,temp_dir_step_exp(j).name));
                temp_dir_step_plate(ismember( {temp_dir_step_plate.name}, {'.', '..'})) = [];  %remove . and ..
                
                for k = 1:length(temp_dir_step_plate)
                    
                    this_bytes_plate = temp_dir_step_plate(k).bytes;
                    
                    if this_bytes_plate < num_bytes_to_keep
                        disp(['Remove ' temp_dir_step_plate(k).name])
                        
                        delete(fullfile(temp_dir_step_plate(k).folder,temp_dir_step_plate(k).name))
                        
                    end
                    
                end
                
                temp_dir_step_plate = dir(fullfile(temp_dir_step_exp(j).folder,temp_dir_step_exp(j).name));
                temp_dir_step_plate(ismember( {temp_dir_step_plate.name}, {'.', '..'})) = [];  %remove . and ..
                
                if rem(length(temp_dir_step_plate),25)
                    disp('WARNING')
                    disp(['Plate ' temp_dir_step_plate(1).folder ' has improper number of images']) 
                end
                                
            catch
                disp(['not correct subfolders in ' temp_dir_step_exp(1).folder])
                break
            end
            
        end
        
        
    end
    
else
    disp('end of script')
end



