
function [names_of_divisions,full_exp_name] = user_input_division_names(exp_dir_path,num_divisions_per_plate,number_of_experiments)

% set up variables 
names_of_divisions = cell(num_divisions_per_plate,length(exp_dir_path));
prompt = cell(1,number_of_experiments+1);
dlgtitle = 'Please enter the corresponding plate division names for each unique experiment';
dims = [1,100];

% repeat the division numbers [1,2,3]->[1,2,3,1,2,3...]
division_numbers = repmat(1:num_divisions_per_plate,1,length(exp_dir_path));

% create the header prompt
prompt{1,1} = 'Overarching experiment name (please no spaces)';

% create each individual prompt
k=2;
for i = 1:length(exp_dir_path)
    thisExp = exp_dir_path{i};
    for j = 1:num_divisions_per_plate
        prompt{1,k} = [thisExp ' division number ' num2str(division_numbers(j))];
        k=k+1;
    end
end

% make the answer form
answers = inputdlg(prompt,dlgtitle,dims);

% read the answers for each experiment
k = 2;
for i = 1:length(exp_dir_path)
    for j = 1:num_divisions_per_plate
        names_of_divisions{j,i} = answers{k};
        k=k+1;
    end
end

% read the full name
full_exp_name = answers{1};

end