function plot_WP_data(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days,final_data_export_path,full_exp_name,sess_nums)

% Separate divisions out 
[sep_exps_days,sep_exps_sess,sep_exps_days_health,sep_nms,censored_wells_any_separated,sep_well_locations] = ...
    separate_divisions(data_storage,censored_wells_any,potential_lifespans_days,...
    potential_lifespans_sess,potential_healthspans_days);

number_of_experiments = length(sep_nms);

for i = 1:number_of_experiments
    this_lifespan = nonzeros(sep_exps_days{i}.*~(censored_wells_any_separated{i}));
    this_healthspan = nonzeros(sep_exps_days_health{i}.*~(censored_wells_any_separated{i}));
    sep_nms2{i} = [sep_nms{i} ' - median lifespan=' num2str(median(this_lifespan)) ' - N=' num2str(length(this_lifespan))];
    sep_nms3{i} = [sep_nms{i} ' - median healthspan=' num2str(median(this_healthspan)) ' - N=' num2str(length(this_lifespan))];
    disp(sep_nms2{i})
    disp(sep_nms3{i})
end

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
    
    this_lifespan = sep_exps_days{i};
    
    worms_remaining{1,i} = sep_nms{i};
    
    worms_remaining_temp = zeros(1,length(stepsize));
    
    for j = 1:length(stepsize)

        worms_remaining_temp(j) = sum(this_lifespan>stepsize(j));

    end
    
    worms_remaining{3,i} = worms_remaining_temp/max(worms_remaining_temp);
    
    plot(worms_remaining{2,i},worms_remaining{3,i},...
        'LineStyle','-','LineWidth',1,...
        'Color',all_colors{i},'Marker',all_marks{i})


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
    
    this_healthspan = sep_exps_days_health{i};
    
    worms_remaining{1,i} = sep_nms{i};
    
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
title(['Combined Healthspans for ' full_exp_name],'Interpreter','none');
ylabel('Percent Healthy')
xlabel('days on robot');
% xlim([1,length(sess_nums{1}-1)])
xticks([1:2:length(sess_nums{1})-1])
legend(sep_nms3, 'interpreter','none')
saveas(g2,char([pwd '/processed_data/' full_exp_name '_health.png']))
saveas(g2,fullfile(final_data_export_path,full_exp_name,[full_exp_name '_health.png']));
hold off






end