% worm isolations 
mkdir('Worm_isolations');

experiment_folder = '/groups/sutphin/testing/DAF2_and_GLS129';

ise = evalin( 'base', 'exist(''newROIs'',''var'') == 1' );
if ~ise
    load([experiment_folder '-data/raw_data/newROIs.mat'])
end
load([experiment_folder '-data/raw_data/peaks.mat'])
load([experiment_folder '-data/processed_data/potential_lifespans.mat']);
load([experiment_folder '-data/processed_data/norm_activity.mat'])
load([experiment_folder '-data/processed_data/runoff_worms.mat'])

proc_imgs_path = ([experiment_folder '-data/processed_data/']);
raw_imgs_path = (experiment_folder);

proc_img_paths = dir(fullfile(proc_imgs_path, '*.png'));
[~,sort_idx,~] = natsort({proc_img_paths.name});
proc_img_paths = proc_img_paths(sort_idx);

raw_img_paths = dir(raw_imgs_path);
raw_img_paths(ismember( {raw_img_paths.name}, {'.', '..'})) = [];  %remove . and ..

k=0;
for i = 1:length(nonzeros(sum(locs,2)))
    for j = 1:length(nonzeros(sum(locs)))
        if ~isempty(newROIs{i,j})
            k=k+1;
            sess_nums(i,j) = k;
        end
    end
end
num_sess = max(sess_nums(:));
newROIs2=cell(1,num_sess);
for j=1:max(sess_nums(:))
    [a,b] = find(sess_nums == j);
    %     disp(num2str([a,b]))
    newROIs2{j} = newROIs{a,b};
end

new_locs = nonzeros(reshape(locs',[numel(locs),1]));

for i = 1:length(raw_img_paths)
    temp_dirstep = dir([raw_img_paths(i).folder '/' raw_img_paths(i).name]);
    temp_dirstep(ismember( {temp_dirstep.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
    daily_dir{i}=temp_dirstep;
end

cut_cells = cell(length(proc_img_paths),240);
for i = 1:length(proc_img_paths)
    
    [a,b] = find(sess_nums == i);
    
% %     disp(['Processing data for day' num2str(a) ' session' num2str(b)]);
    
    temp_dir = daily_dir{a};
    
    s = regionprops(newROIs2{i},'BoundingBox');
    
    raw_img = imread(fullfile(temp_dir(new_locs(i)+1).folder,temp_dir(new_locs(i)+1).name));
%     proc_img = imread(fullfile(proc_img_paths(i).folder,proc_img_paths(i).name));
        
    for j = 1:length(s)
        xMin = ceil(s(j).BoundingBox(1));
        xMax = xMin + s(j).BoundingBox(3) - 1;
        yMin = ceil(s(j).BoundingBox(2));
        yMax = yMin + s(j).BoundingBox(4) - 1;
        % Then this removes all the wells from large images
        % and removes everything that isnt the wells
        temp_img = raw_img(yMin:yMax,xMin:xMax);
        
        cut_cells{i,j} = insertText(temp_img,[10,10],num2str(i),'FontSize',18,'BoxColor',...
            'yellow','BoxOpacity',0.4,'TextColor','white');
        
        if i == potential_lifespans_sess(j)
            cut_cells{i,j} = insertText(cut_cells{i,j},[30,10],'Death','FontSize',18,'BoxColor',...
                'red','BoxOpacity',0.4,'TextColor','white');
        end
    end
    
end


for i = 1:240
    
   A = imtile(cut_cells(:,i),'BackgroundColor','white','BorderSize',[2,2]);
   
   imwrite(A,['Worm_isolations/' num2str(i) '.png'])
    

end







