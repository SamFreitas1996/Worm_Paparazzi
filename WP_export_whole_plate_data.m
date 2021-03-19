function WP_export_whole_plate_data(export_data,censored_wells_runoff,data_storage,exp_nm,this_exp_num,sess_nums,num_days)


load([data_storage 'processed_data/norm_activity.mat']);
load([data_storage 'processed_data/potential_lifespans.mat']);

% if a well is censored then it is stored as a 1, reverse that and multiply
potential_lifespans_days_runoff = (potential_lifespans_days.*(~censored_wells_runoff));
potential_lifespans_sess_runoff = (potential_lifespans_sess.*(~censored_wells_runoff));

sess_diff = abs(raw_sess_data_aft - raw_sess_data_bef);

if export_data
    
    mkdir([pwd '/processed_data']);
    
    % write te potential lifespans to a .csv for R or other stuff
    writematrix(gather(potential_lifespans_days_runoff), char([pwd '/processed_data/' exp_nm '.csv']));
    
    % sort the lifepsan sessions by amount lived
    % B is the sorted array
    % idx "sort index" that tells you where the sorted array came from
    [B,idx]=sort(potential_lifespans_sess_runoff);
    
    % find all the worm well numbers that were above the 0 day threshold of
    % lifespan
    % this represents all the worms that didnt run off as a sorted array
    % from shortest lifespan to longest lifespan
    % if 
    worm_well_number=idx(B>1);
    
    worm_activity=cell(1,240);
    for i = 1:240
        %         worm_activity{i} = raw_norm_curves(:,i);
        worm_activity{i} = sess_diff(:,i);
    end
    
    life_curve_picture = zeros(length(worm_well_number),length(median_norm_data2));
    for i = 1:length(worm_well_number)
        
        thisActivity = gather(worm_activity{worm_well_number(i)});
        
        thisActivity(potential_lifespans_sess_runoff(worm_well_number(i))+1:end)=0;
        
        life_curve_picture(i,:) = thisActivity;
        
    end
    
    h=figure(this_exp_num);
    
    imshow(life_curve_picture,[]);
    c= colorbar('TickLabels',{'Low','High'},'Ticks',[min(life_curve_picture(:)),max(life_curve_picture(:))]);
    c.Label.String = {'Activity per session for each worm'; ' '; 'Red dot indicates day of death'};
    xlabel({'Days on robot'; ' ' ;['Median lifespan - ' num2str(median(nonzeros(potential_lifespans_days_runoff)))] });
    ylabel('worms sorted by lifespan');
    title([exp_nm ' processed on: ' date], 'interpreter','none')
    
    hold on
    for i=1:length(worm_well_number)
        
        plot(potential_lifespans_sess_runoff(worm_well_number(i)),i,'ro')
        
    end
    ticks_numbers = sess_nums(:,1);
    ticks_numbers = ticks_numbers(1:2:end);
    ticks_labels = string([1:2:num_days]);
    axis on
    set(gca,'XTick',ticks_numbers)
    set(gca,'YTick',[1:10:length(life_curve_picture(:,1))])
    set(gca,'XTickLabels',ticks_labels)
    set(h, 'Position', get(0, 'Screensize'));
    
    hold off
    
    pause(.2)
    
    saveas(h,char([pwd '/processed_data/' exp_nm '.png']))
    
    
    
    goodwells = nonzeros( (1:240).*(~censored_wells));
    
% %     median_lifespan_data = load([data_dir(1).folder '/' data_names{round(median(nonzeros(potential_lifespans_sess)))}]);
% %     sess_activity_integral = (double(imfuse(gather(sess_data.zstack_bef),gather(sess_data.zstack_aft),'diff','Scaling','joint')));
% %     
% %     if reduce_final_noise
% %         sess_activity_integral = bwareaopen((sess_activity_integral>2),15).*sess_activity_integral;
% %     end
% %     
% %     median_lifespan_image = double(logical(imread([data_storage 'processed_data/sess_' num2str(round(median(nonzeros(potential_lifespans_sess)))) '.png'])));
% %     
% %     censored_ROI=zeros(size(median_lifespan_data.thisROI));
% %     for i =1:240
% %         
% %         if ~censored_wells2(i)
% %             censored_ROI = censored_ROI + i*double(median_lifespan_data.thisROI==i);
% %         end
% %         
% %     end
% %     
% %     median_lifespan_image=(3*median_lifespan_image.*(censored_ROI>0) + double(censored_ROI>0));
% %     
% %     
% %     imwrite(median_lifespan_image/max(median_lifespan_image(:)),[pwd '/processed_data/' exp_nm '_med_LS.png'])
% %     
%     figure;
%     imshow(median_lifespan_image,[])
%     title('Median lifespan image with noncensored wells');
    
    disp(['Median lifespan for experiment: ' exp_nm ' -- ' num2str(median(nonzeros(potential_lifespans_days_runoff))) ' days on robot']);
    
end
end
