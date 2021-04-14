function WP_export_whole_plate_data_daily(export_data,censored_wells_runoff,data_storage,...
    exp_nm,this_exp_num,sess_nums,num_days,final_data_export_path,full_exp_name,data_points_to_omit)


load([data_storage 'processed_data/norm_activity.mat']);
load([data_storage 'processed_data/potential_lifespans.mat']);

% if a well is censored then it is stored as a 1, reverse that and multiply
potential_lifespans_days_runoff = (potential_lifespans_days.*(~censored_wells_runoff));
potential_lifespans_sess_runoff = (potential_lifespans_sess.*(~censored_wells_runoff));
potential_healthspans_days_runoff = (potential_healthspans_days.*(~censored_wells_runoff));
if num_days < 5
    num_days = length(sess_nums);
end

sess_diff = abs(raw_sess_data_aft_bw + raw_sess_data_bef_bw);

if export_data
    
    mkdir([pwd '/processed_data']);
    
    % write te potential lifespans to a .csv for R or other stuff
    writematrix(gather(potential_lifespans_days_runoff), char([pwd '/processed_data/' exp_nm '.csv']));
    
    % sort the lifepsan sessions by amount lived
    % B is the sorted array
    % idx "sort index" that tells you where the sorted array came from
    [sorted_lifespans,idx_lifespan]=sort(potential_lifespans_days_runoff);
    [sorted_healthspan,idx_healthspan]=sort(potential_healthspans_days_runoff);
    
    % find all the worm well numbers that were above the 0 day threshold of
    % lifespan
    % this represents all the worms that didnt run off as a sorted array
    % from shortest lifespan to longest lifespan
    % if 
    worm_well_number_lifespan=idx_lifespan(sorted_lifespans>1);
    worm_well_number_healthspan=idx_healthspan(sorted_healthspan>0);
    
    worm_activity=cell(1,240);
    for i = 1:240
        %         worm_activity{i} = raw_norm_curves(:,i);
        this_worm_bw = sess_diff(:,i);
        
        this_worm_bw(data_points_to_omit) = 0;
        
        this_worm_bw2 = NaN(size(sess_nums));
        for j = 1:length(this_worm_bw)
            [a,b] = find(sess_nums == j);
            this_worm_bw2(a,b) = this_worm_bw(j);
        end
        worm_activity{i} = mean(this_worm_bw2,2,'omitnan');
        worm_activity_scaler(i) = max(worm_activity{i});
    end
    
    worm_activity_scaler = max(worm_activity_scaler);
    
    life_curve_picture = zeros(length(worm_well_number_lifespan),num_days);
    for i = 1:length(worm_well_number_lifespan)
        
        thisActivity = gather(worm_activity{worm_well_number_lifespan(i)})/worm_activity_scaler;
        
        thisActivity(potential_lifespans_sess_runoff(worm_well_number_lifespan(i))+1:end)=0;
        
        life_curve_picture(i,:) = thisActivity;
        
    end
    
    health_curve_picture = zeros(length(worm_well_number_healthspan),num_days);
    for i = 1:length(worm_well_number_healthspan)
        
        thisActivity = gather(worm_activity{worm_well_number_healthspan(i)})/worm_activity_scaler;
        
        thisActivity(potential_lifespans_sess_runoff(worm_well_number_healthspan(i))+1:end)=0;
        
        health_curve_picture(i,:) = thisActivity;
        
    end
    
%     h=figure(this_exp_num);
%     
%     imshow(life_curve_picture,[]);
%     c= colorbar('TickLabels',{'Low','High'},'Ticks',[min(life_curve_picture(:)),max(life_curve_picture(:))]);
%     c.Label.String = {'Activity per session for each worm'; ' '; 'Red dot indicates day of death';' ';'Green dot indicates end of health'};
%     xlabel({'Days on robot'; ' ' ;['Median lifespan - ' num2str(median(nonzeros(potential_lifespans_days_runoff)))] });
%     ylabel('worms sorted by lifespan');
%     title([exp_nm ' processed on: ' date], 'interpreter','none')
%     
%     hold on
%     for i=1:length(worm_well_number_lifespan)
%         
%         plot(potential_lifespans_sess_runoff(worm_well_number_lifespan(i)),i,'ro')
%         plot(potential_healthspans_days_runoff(worm_well_number_lifespan(i)),i,'go')
%         
%     end
% 
%     ticks_labels = string([1:10:num_days]);
%     axis on
%     set(gca,'XTick',[1:10:num_days])
%     set(gca,'YTick',[1:10:length(life_curve_picture(:,1))])
%     set(h, 'Position', get(0, 'Screensize'));
%     
%     hold off
%     h=figure(this_exp_num);
%     
%     imshow(life_curve_picture,[]);
%     c= colorbar('TickLabels',{'Low','High'},'Ticks',[min(life_curve_picture(:)),max(life_curve_picture(:))]);
%     c.Label.String = {'Activity per session for each worm'; ' '; 'Red dot indicates day of death';' ';'Green dot indicates end of health'};
%     xlabel({'Days on robot'; ' ' ;['Median lifespan - ' num2str(median(nonzeros(potential_lifespans_days_runoff)))] });
%     ylabel('worms sorted by lifespan');
%     title([exp_nm ' processed on: ' date], 'interpreter','none')
%     
%     hold on
%     for i=1:length(worm_well_number_lifespan)
%         
%         plot(potential_lifespans_sess_runoff(worm_well_number_lifespan(i)),i,'ro')
%         plot(potential_healthspans_days_runoff(worm_well_number_lifespan(i)),i,'go')
%         
%     end
% 
%     ticks_labels = string([1:10:num_days]);
%     axis on
%     set(gca,'XTick',[1:10:num_days])
%     set(gca,'YTick',[1:10:length(life_curve_picture(:,1))])
%     set(h, 'Position', get(0, 'Screensize'));
%     
%     hold off
    h=figure(this_exp_num);
    subplot(1,2,1)
    imshow(life_curve_picture,[]);
    c= colorbar('TickLabels',{'Low','High'},'Ticks',[min(life_curve_picture(:)),max(life_curve_picture(:))]);
    c.Label.String = {'Activity per session for each worm'; ' '; 'Red dot indicates day of death';' ';'Green dot indicates end of health'};
    xlabel({'Days on robot'; ' ' ;['Median lifespan - ' num2str(median(nonzeros(potential_lifespans_days_runoff)))] });
    ylabel('worms sorted by lifespan');
    title([exp_nm ' processed on: ' date], 'interpreter','none')
    hold on
    for i=1:length(worm_well_number_lifespan)
        subplot(1,2,1)
        plot(potential_lifespans_sess_runoff(worm_well_number_lifespan(i)),i,'ro')
        plot(potential_healthspans_days_runoff(worm_well_number_lifespan(i)),i,'go')
    end
    axis on
    set(gca,'XTick',[1:4:num_days])
    set(gca,'YTick',[1:10:length(life_curve_picture(:,1))])
    set(h, 'Position', get(0, 'Screensize'));
    hold off
    subplot(1,2,2)
    imshow(health_curve_picture,[]);
    c= colorbar('TickLabels',{'Low','High'},'Ticks',[min(life_curve_picture(:)),max(life_curve_picture(:))]);
    c.Label.String = {'Activity per session for each worm'; ' '; 'Red dot indicates day of death';' ';'Green dot indicates end of health'};
    xlabel({'Days on robot'; ' ' ;['Median healthspan - ' num2str(median(nonzeros(potential_healthspans_days_runoff)))] });
    ylabel('worms sorted by healthspan');
    title([exp_nm ' processed on: ' date], 'interpreter','none')
    hold on
    for i=1:length(worm_well_number_healthspan)
        subplot(1,2,2)
        plot(potential_lifespans_sess_runoff(worm_well_number_healthspan(i)),i,'ro')
        plot(potential_healthspans_days_runoff(worm_well_number_healthspan(i)),i,'go')
    end
    axis on
    set(gca,'XTick',[1:4:num_days])
    set(gca,'YTick',[1:10:length(life_curve_picture(:,1))])
    set(h, 'Position', get(0, 'Screensize'));
    hold off
    
    pause(.2)
    
    saveas(h,char([pwd '/processed_data/' exp_nm '.png']))
    mkdir(fullfile(final_data_export_path,full_exp_name,'activity_plots'));
    saveas(h,fullfile(final_data_export_path,full_exp_name,'activity_plots',[exp_nm '.png']));
    
    
    disp(['Median lifespan for experiment: ' exp_nm ' -- ' num2str(median(nonzeros(potential_lifespans_days_runoff))) ' days on robot']);
    
end
end
