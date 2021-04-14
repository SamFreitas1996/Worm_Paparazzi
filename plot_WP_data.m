function plot_WP_data(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days,final_data_export_path,full_exp_name,sess_nums,group_similar_data,use_ecdf)

% Separate divisions out
[sep_exps_days,sep_exps_sess,sep_exps_days_health,sep_nms_full,censored_wells_any_separated,sep_well_locations,...
    dosage_names,strain_names] = ...
    separate_divisions(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days);


if group_similar_data
    
    disp('Grouping seperate plate data together with the same name')
    
    sep_nms_unique = unique(sep_nms_full);
    
    temp_sep_exps_days = cell(1,length(sep_nms_unique));
    temp_sep_exps_sess = cell(1,length(sep_nms_unique));
    temp_sep_exps_days_health = cell(1,length(sep_nms_unique));
    temp_cen_all = cell(1,length(sep_nms_unique));
    
    
    for i = 1:length(sep_nms_unique)
        
        this_idx = find(string(sep_nms_unique{i})==string(sep_nms_full));
        
        temp_sep_exps_days{i} = cell2mat(sep_exps_days(this_idx));
        temp_sep_exps_sess{i} = cell2mat(sep_exps_sess(this_idx));
        temp_sep_exps_days_health{i} = cell2mat(sep_exps_days_health(this_idx));
        temp_cen_all{i} = cell2mat(censored_wells_any_separated(this_idx));
        
    end
    
    sep_nms_full = sep_nms_unique;
    sep_exps_days = temp_sep_exps_days;
    sep_exps_sess = temp_sep_exps_sess;
    sep_exps_days_health = temp_sep_exps_days_health;
    censored_wells_any_separated = temp_cen_all;
    
    clear sep_nms_unique temp_sep_exps_days temp_sep_exps_sess temp_sep_exps_days_health temp_cen_all
    
end

number_of_experiments = length(sep_nms_full);

for i = 1:number_of_experiments
    this_lifespan = nonzeros(sep_exps_days{i}.*~(censored_wells_any_separated{i}));
    this_healthspan = nonzeros(sep_exps_days_health{i}.*~(censored_wells_any_separated{i}));
    sep_nms2{i} = [sep_nms_full{i} ' - median lifespan=' num2str(median(this_lifespan)) ' - N=' num2str(length(this_lifespan))];
    sep_nms3{i} = [sep_nms_full{i} ' - median healthspan=' num2str(median(this_healthspan)) ' - N=' num2str(length(this_lifespan))];
    disp(sep_nms2{i})
    disp(sep_nms3{i})
end

clear this_lifespan this_healthspan

worms_remaining = cell(3,number_of_experiments);
all_marks = {'o','+','*','.','x','s','d','^','p','h','o','+','*','.','x','s','d','^','p','h','o','+','*','.','x','s','d','^','p','h','o','+','*','.','x','s','d','^','p','h'};
all_colors = {'r','g','b','k','m','c','r','g','b','k','y','m','c','r','g','b','k','y','m','c','r','g','b','k','r','g','b','k','m','c','r','g','b','k','y','m','c','r','g','b','k','y','m','c','r','g','b','k'};
% top - experiment name
% middle - experiment time scale
% bottom - experiment results
% close all
g = figure('units','normalized','outerposition',[0 0 1 1]);
% g.WindowState = 'maximized';
hold on
for i = 1:number_of_experiments
    
    stepsize = 1:(max(sep_exps_days{i})+1);
    
    worms_remaining{2,i} = stepsize;
    
    %     this_lifespan = sep_exps_days{i};
    
    if use_ecdf
        [this_survival_curve,x] = ecdf(sep_exps_days{i},'censoring',censored_wells_any_separated{i},'function','survivor');
        
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',1,...
            'Color',all_colors{i},'Marker',all_marks{i})
    else
        this_lifespan = nonzeros(sep_exps_days{i}.*~(censored_wells_any_separated{i}));
        
        worms_remaining{1,i} = sep_nms_full{i};
        
        worms_remaining_temp = zeros(1,length(stepsize));
        
        for j = 1:length(stepsize)
            
            worms_remaining_temp(j) = sum(this_lifespan>stepsize(j));
            
        end
        
        worms_remaining{3,i} = worms_remaining_temp/max(worms_remaining_temp);
        
        plot(worms_remaining{2,i},worms_remaining{3,i},...
            'LineStyle','-','LineWidth',1,...
            'Color',all_colors{i},'Marker',all_marks{i})
    end
    
end
title(['Combined lifespans for ' full_exp_name],'Interpreter','none');
ylabel('Percent remaining')
xlabel('days survived on robot');
% xlim([1,length(sess_nums{1}-1)])
xticks([1:2:length(sess_nums{1})-1])
legend(sep_nms2, 'interpreter','none')
saveas(g,char([pwd '/processed_data/' full_exp_name '.png']))
saveas(g,fullfile(final_data_export_path,full_exp_name,[full_exp_name '.png']));
hold off










worms_remaining = cell(3,number_of_experiments);
% top - experiment name
% middle - experiment time scale
% bottom - experiment results
% close all
g2 = figure('units','normalized','outerposition',[0 0 1 1]);
% g.WindowState = 'maximized';
hold on
for i = 1:number_of_experiments
    
    stepsize = 1:(max(sep_exps_days_health{i})+1);
    
    worms_remaining{2,i} = stepsize;
    
    %     this_healthspan = sep_exps_days_health{i};
    if use_ecdf
        [this_survival_curve,x] = ecdf(sep_exps_days_health{i},'censoring',censored_wells_any_separated{i},'function','survivor');
        
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',1,...
            'Color',all_colors{i},'Marker',all_marks{i})
    else
        this_healthspan = nonzeros(sep_exps_days_health{i}.*~(censored_wells_any_separated{i}));
        
        worms_remaining{1,i} = sep_nms_full{i};
        
        worms_remaining_temp = zeros(1,length(stepsize));
        
        for j = 1:length(stepsize)
            
            worms_remaining_temp(j) = sum(this_healthspan>stepsize(j));
            
        end
        
        worms_remaining{3,i} = worms_remaining_temp/max(worms_remaining_temp);
        
        %     plot(worms_remaining{2,i},worms_remaining{3,i},'LineStyle','-','Color',all_colors{i},'Marker',all_marks{i})
        plot(worms_remaining{2,i},worms_remaining{3,i},...
            'LineStyle','-','LineWidth',1,...
            'Color',all_colors{i},'Marker',all_marks{i})
    end
    
end
title(['Combined Healthspans for ' full_exp_name],'Interpreter','none');
ylabel('Percent Healthy')
xlabel('days on robot');
% xlim([1,length(sess_nums{1}-1)])
xticks([1:2:length(sess_nums{1})-1])
legend(sep_nms3, 'interpreter','none')
saveas(g2,char([pwd '/processed_data/' full_exp_name '_health.png']))
saveas(g2,fullfile(final_data_export_path,full_exp_name,[full_exp_name '_health.png']));
hold off


if group_similar_data
    
    mkdir(fullfile(final_data_export_path,full_exp_name,'groupings'));
    
    groupings = [cellstr(dosage_names);cellstr(strain_names)];
    
    for k = 1:length(groupings)
        groupings_save_name{k} = strrep(groupings{k},'/','_');
    end
    % group by dosage
    
    % group by strain
    
%     groupings = cellstr(strain_names);
    
    for k = 1:length(groupings)
        
        this_grouping = zeros(1,length(sep_nms_full));
        
        for m = 1:length(sep_nms_full)
            
            str_split_nms = split(sep_nms_full{m}, ' - ');
            
            for n = 1:length(str_split_nms)
                this_grouping(m) = strcmp(str_split_nms{n},groupings{k});
                if this_grouping(m)
                    break
                end
            end
            
        end
        
        number_of_experiments_group = sum(this_grouping);
        
        this_grouping_idx = nonzeros((1:length(this_grouping)).*(this_grouping));
        
        clear this_lifespan this_healthspan
        
        worms_remaining = cell(3,number_of_experiments_group);
        all_marks = {'o','+','*','.','x','s','d','^','p','h','o','+','*','.','x','s','d','^','p','h','o','+','*','.','x','s','d','^','p','h','o','+','*','.','x','s','d','^','p','h'};
        all_colors = {'r','g','b','k','m','c','r','g','b','k','y','m','c','r','g','b','k','y','m','c','r','g','b','k','r','g','b','k','m','c','r','g','b','k','y','m','c','r','g','b','k','y','m','c','r','g','b','k'};
        % top - experiment name
        % middle - experiment time scale
        % bottom - experiment results
        % close all
        g = figure('units','normalized','outerposition',[0 0 1 1]);
        % g.WindowState = 'maximized';
        hold on
        for i = 1:number_of_experiments_group
            
            stepsize = 1:(max(sep_exps_days{this_grouping_idx(i)})+1);
            
            worms_remaining{2,i} = stepsize;
            
            %     this_lifespan = sep_exps_days{i};
            
            if use_ecdf
                [this_survival_curve,x] = ecdf(sep_exps_days{this_grouping_idx(i)},'censoring',censored_wells_any_separated{this_grouping_idx(i)},'function','survivor');
                
                plot(x,this_survival_curve,...
                    'LineStyle','-','LineWidth',1,...
                    'Color',all_colors{i},'Marker',all_marks{i})
            else
                this_lifespan = nonzeros(sep_exps_days{this_grouping_idx(i)}.*~(censored_wells_any_separated{this_grouping_idx(i)}));
                
                worms_remaining{1,i} = sep_nms_full{this_grouping_idx(i)};
                
                worms_remaining_temp = zeros(1,length(stepsize));
                
                for j = 1:length(stepsize)
                    
                    worms_remaining_temp(j) = sum(this_lifespan>stepsize(j));
                    
                end
                
                worms_remaining{3,i} = worms_remaining_temp/max(worms_remaining_temp);
                
                plot(worms_remaining{2,i},worms_remaining{3,i},...
                    'LineStyle','-','LineWidth',1,...
                    'Color',all_colors{i},'Marker',all_marks{i})
            end
            
        end
        title(['Combined lifespans for ' full_exp_name '-' char(groupings(k))],'Interpreter','none');
        ylabel('Percent remaining')
        xlabel('days survived on robot');
        % xlim([1,length(sess_nums{1}-1)])
        xticks([1:2:length(sess_nums{1})-1])
        legend(sep_nms2(this_grouping_idx), 'interpreter','none')
        saveas(g,char([pwd '/processed_data/' full_exp_name  '-' char(groupings_save_name(k)) '.png']))
        saveas(g,fullfile(final_data_export_path,full_exp_name,'groupings',[full_exp_name '-' char(groupings_save_name(k)) '.png']));
        hold off
        
    end
    
    
end


end