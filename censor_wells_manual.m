% manually find the cencored wells 

function censored_wells = censor_wells_manual(exp_dir,newROIs,~,~)
% NoI = [100,3,3,3]; % number of iterations
% NoL = 6;  % number of pyramid-levels % changed to 4????????
% transform = 'affine';
% init=[eye(2) 20*ones(2,1)];%translation-only initialization

day_to_load=round(length(exp_dir));
temp_dirstep=dir([exp_dir(day_to_load).folder '/' exp_dir(day_to_load).name]);
temp_dirstep(ismember( {temp_dirstep.name}, {'.', '..'})) = [];  %remove . and ..

first_image = double(imread([temp_dirstep(1).folder '/' temp_dirstep(15).name]));
% Load the middle session's data

clear idx_cen

ROI_overlay=newROIs{day_to_load,1};

% user selects wells that need to be censored
redo=char('Yes');
while strcmpi(redo,'Yes')
    h=figure('units','normalized','outerposition',[0 0 1 1],...
        'NumberTitle','Off',...
        'Name','Censor selection window'); imshow(first_image.*(ROI_overlay>0),[]);
    title('Select the center of the wells that need to be censored --- double-click anywhere to end')
    [x,y]=getpts();
    hold on;
    plot(x,y,'r*')

    redo = questdlg('Do you want to redo this censor? (double-click point not saved)','Redo?','Yes','No','No');
    close(h);
end
censored_wells=zeros(1,240);
% creates the censor variable

censor_userSelected=zeros(1,length(x)-1);
for i = 1: length(x)-1
    try
        if ROI_overlay(round(y(i)),round(x(i)))>0   % makes sure an actual ROI was selected
            censor_userSelected(i)=ROI_overlay(round(y(i)),round(x(i)));
        else
            censor_userSelected(i)=0;
        end
    catch
        censor_userSelected(i)=0;
        disp('Censoring error, ignoring')
    end
end

censored_wells(round(nonzeros(censor_userSelected)))=1;

image_temp = zeros(size(ROI_overlay));
for i = 1:240
    if censored_wells(i) == 1
        image_temp = image_temp + double(round(ROI_overlay)==i);
    end
end
h=figure;
imshow(~image_temp.*first_image,[]); title('Showing all wells that will NOT be censored');

pause(5);
close(h)

end