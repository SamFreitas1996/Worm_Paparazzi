function create_new_training_data_nn(worms_nn_predicted,images,number_loaded)

inital_runoff = ~logical(sum(worms_nn_predicted>.75,2));

disp('Creating new training data for the neural network (will take a couple minutes)')

mkdir([pwd '/new_images_for_model']);
mkdir([pwd '/new_images_for_model/worms']);
mkdir([pwd '/new_images_for_model/no_worms']);

worms_dir = dir([pwd '/new_images_for_model/worms']);
worms_dir(ismember( {worms_dir.name}, {'.', '..'})) = [];  %remove . and ..
no_worms_dir = dir([pwd '/new_images_for_model/no_worms']);
no_worms_dir(ismember( {no_worms_dir.name}, {'.', '..'})) = [];  %remove . and ..

no_worms_start = length(no_worms_dir) + 1;
worms_start = length(worms_dir) + 1;

no_worms_idx = no_worms_start;
worms_idx = worms_start;
for i = 1:length(inital_runoff)
    
    disp(i)
    
    well_imgs = images(i,:);
    
    % if the worms were censored 
    if inital_runoff(i)
        
        for j = 1:length(well_imgs)
            imwrite(well_imgs{j},[pwd '/new_images_for_model/no_worms/' num2str(no_worms_idx) '.png'])
            no_worms_idx = no_worms_idx+1;
        end
        
    else
        
        for j = 1:length(well_imgs)
            imwrite(well_imgs{j},[pwd '/new_images_for_model/worms/' num2str(worms_idx) '.png'])
            worms_idx = worms_idx+1;
        end
    end
    
end

end