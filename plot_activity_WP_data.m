function plot_activity_WP_data(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days,final_data_export_path,...
    full_exp_name,sess_nums,group_similar_data,use_ecdf,add_control_to_everything,worm_daily_activity)


% Separate divisions out
[sep_exps_days,sep_exps_sess,sep_exps_days_health,sep_nms_full,censored_wells_any_separated,sep_well_locations,...
    dosage_names,strain_names,activities_full] = ...
    separate_divisions(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days,worm_daily_activity);


if group_similar_data
    
    disp('Grouping seperate plate data together with the same name')
    
    sep_nms_unique = natsort(unique(sep_nms_full));
    
    temp_sep_exps_days = cell(1,length(sep_nms_unique));
    temp_sep_exps_sess = cell(1,length(sep_nms_unique));
    temp_sep_exps_days_health = cell(1,length(sep_nms_unique));
    temp_cen_all = cell(1,length(sep_nms_unique));
    temp_sep_activity_days = cell(1,length(sep_nms_unique));
    
    for i = 1:length(sep_nms_unique)
        
        this_idx = find(string(sep_nms_unique{i})==string(sep_nms_full));
        
        temp_sep_exps_days{i} = cell2mat(sep_exps_days(this_idx));
        temp_sep_exps_sess{i} = cell2mat(sep_exps_sess(this_idx));
        temp_sep_exps_days_health{i} = cell2mat(sep_exps_days_health(this_idx));
        temp_cen_all{i} = cell2mat(censored_wells_any_separated(this_idx));
        temp_act = activities_full(this_idx);
        temp_act2 = {};
        for j = 1:length(temp_act)
            temp_act2 = [temp_act2, temp_act{j}];
        end
        temp_sep_activity_days{i} = temp_act2;
        
    end
    
    sep_nms_full = sep_nms_unique;
    sep_exps_days = temp_sep_exps_days;
    sep_exps_sess = temp_sep_exps_sess;
    sep_exps_days_health = temp_sep_exps_days_health;
    censored_wells_any_separated = temp_cen_all;
    activities_full = temp_sep_activity_days;
    
    for k = 1:length(sep_nms_full)
        groupings_save_name{k} = strrep(sep_nms_full{k},'/','_');
    end
    
    clear sep_nms_unique temp_sep_exps_days temp_sep_exps_sess temp_sep_exps_days_health temp_cen_all
    
end

overall_max_life = max(cellfun(@max,sep_exps_days));

mkdir(fullfile(final_data_export_path,full_exp_name,'activity_groupings'));

for i = 1:length(sep_nms_full)
        
    [~,sort_idx] = sort(sep_exps_days{i});
    
    this_grouping_name = sep_nms_full{i};
    this_exps_days = sep_exps_days{i}(sort_idx);
    this_activity_days = activities_full{i}(sort_idx);
    this_cen_any = censored_wells_any_separated{i}(sort_idx);
        
    this_activity_img = zeros(length(this_activity_days)-sum(this_cen_any),overall_max_life);
    
    k=1;
    for j = 1:length(this_activity_days)
        if ~(this_cen_any(j))
            try
                this_activity_img(k,:) = this_activity_days{j}(1:overall_max_life);
            catch
                idx_life = 1:length(this_activity_days{j}(1:end));
                this_activity_img(k,idx_life) = this_activity_days{j}(1:end);
            end
            this_activity_img(k,this_exps_days(j):end) = 0;
            k=k+1;
        end
    end
    % delete black space
%     this_activity_img(:,(max(this_exps_days)+1):end) = [];
    % convert to RGB image
    temp_img = ind2rgb(round(rescale(this_activity_img,1,length(unique(this_activity_img(:)))))...
        , parula(length(unique(this_activity_img(:)))));
    % make it square
    temp_img = imresize(temp_img,[size(temp_img,1),size(temp_img,1)]);
    
    this_exps_days_scaled = ceil((this_exps_days/overall_max_life)*length(temp_img));
    k=1;
    for j = 1:length(this_activity_days)
        if ~(this_cen_any(j))
            temp_img(k,this_exps_days_scaled(j),:) = [255,0,0];
            k=k+1;
        end
    end    
    % scale it up
    
    this_scale_transform = round(500/size(temp_img,1))*size(temp_img,1);
        
    temp_img = imresize(temp_img,[this_scale_transform,this_scale_transform],'nearest');
    
    num_worms = sum(~(this_cen_any));
    
    good_worms = this_exps_days.*(~(this_cen_any));
    
    g = figure('units','normalized','outerposition',[0 0 1 1]);
%     subplot(2,1,1)
    imshow(temp_img)
    c = colorbar('Ticks',[0,0.5,1],...
        'TickLabels', {'none','medium','high'});
    c.Label.String = {'Activity per worm normalized per experiment','Red indicates day of death'};
    axis on
    xlabel({'time (days) survived on robot',['Median lifespan - ' num2str(median(nonzeros(good_worms))) ' days on robot']})
    xticks_idx = linspace(1,length(temp_img),10);
    xticks_idx_labels = string(round(linspace(1,overall_max_life,10)));
    xticks(xticks_idx)
    xticklabels(xticks_idx_labels)
    ylabel('Worm number')
    yticks_idx = linspace(1,length(temp_img),5);
    yticks_idx_labels = string(round(linspace(1,num_worms,5)));
    yticks(yticks_idx)
    yticklabels(yticks_idx_labels)
    title(this_grouping_name,'Interpreter','none')
    
%     subplot(2,1,2)
%     
%     integral_image = sum(this_activity_img)/max(sum(this_activity_img));
%     
%     integral_image = imresize(integral_image,[2,length(this_activity_img)]);
%     
%     integral_image = ind2rgb(round(rescale(integral_image,1,length(unique(integral_image(:)))))...
%         , parula(length(unique(integral_image(:)))));
%     
%     imshow(integral_image)
    
    savename_this_fig = fullfile(final_data_export_path,full_exp_name,'activity_groupings',[groupings_save_name{i} '.png']);
    saveas(g,savename_this_fig)
        
end




end