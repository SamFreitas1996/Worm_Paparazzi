
function [output] = covert_yolo_csv_to_cell()

% find the file

path_to_csv = fullfile(pwd,'results','*.csv');

dir_to_csv = dir(path_to_csv);

csv_table = readtable(fullfile(dir_to_csv.folder,dir_to_csv.name));

csv_array = table2array(csv_table);

output = csv_array;

end