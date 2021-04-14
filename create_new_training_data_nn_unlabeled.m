function create_new_training_data_nn_unlabeled(worms_nn_predicted,images)

inital_runoff = ~logical(sum(worms_nn_predicted>.75,2));

disp('Creating new training data for the neural network (will take a couple minutes)')

mkdir([pwd '/new_images_for_model']);

unabeled_dir = dir(fullfile([pwd '/new_images_for_model'],'*.jpg'));
unabeled_dir(ismember( {unabeled_dir.name}, {'.', '..'})) = [];  %remove . and ..
 
num_images = length(images);
num_days = num_images/240;

if isempty(unabeled_dir)
    all_worms_counter = 1;
else
    all_worms_counter = length(unabeled_dir) +1;
end


for i = 1:240
    
    idx = [((num_days*(i-1))+ 1 ):(num_days*(i-1) + 5) , (num_days*i - 4):(num_days*i)];
        
    well_imgs = images(idx);
    
    
    for j = 1:length(well_imgs)
        imwrite(well_imgs{j},fullfile(pwd,'new_images_for_model', [num2str(all_worms_counter) '.jpg']))
        all_worms_counter = all_worms_counter+1;
    end
    
    
end

disp('finished creating unlabeled data for a new NN')

end