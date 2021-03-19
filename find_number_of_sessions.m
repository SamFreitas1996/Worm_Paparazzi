% find the number and specifics of each recorded day 

function [sess_per_day,pks,locs]=find_number_of_sessions(exp_dir,show_plots_peaks)
    
% hard coded might mess up eventually if more than 4 sessions detected
pks=zeros(length(exp_dir),4);
locs=zeros(length(exp_dir),4);

sess_per_day = zeros(1,length(exp_dir));
for i = 1:length(exp_dir)

    temp_folder = dir(fullfile([exp_dir(i).folder '/' exp_dir(i).name],'*.png'));
    temp_folder(ismember( {temp_folder.name}, {'.', '..','raw_data','raw_data.mat'})) = [];  %remove . and ..
    
    disp(['Finding Identification for day: ' num2str(i)])
    sums=zeros(1,length(temp_folder));
    for ii = 1:length(temp_folder)
        temp_img = imread([temp_folder(ii).folder '/' temp_folder(ii).name]);
%         avgs(ii) = mean(temp_img(:));
        sums(ii) = sum(temp_img(:));
    end
    [pks_temp,locs_temp]=findpeaks(sums,'MinPeakDistance',10,'Threshold',10000000);
    
    num_sessions = length(pks_temp);
    disp(['found: ' num2str(num_sessions) ' sessions/peaks']);
    
    if show_plots_peaks
        figure(i); 
        plot(1:length(sums),sums,'b',locs_temp,pks_temp,'ro');title(['Day: ' num2str(i)])
        drawnow
    end
    
    num_images=length(temp_folder);
    sess_per_day(i)=num_sessions;
    pks(i,(1:length(pks_temp)))=pks_temp;
    locs(i,(1:length(locs_temp)))=locs_temp;
end


end