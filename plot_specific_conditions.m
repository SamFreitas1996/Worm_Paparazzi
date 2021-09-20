clear all
close all force hidden
warning('off', 'MATLAB:MKDIR:DirectoryExists');

% unless you have more than 5/6 different conditions
% dont use markers they look bad
use_markers = 0;

% Generally titles are not necessary in published figures;
use_title = 0;

% only used for combining single conditions across multiple experiments
combine_everything_into_one = 0;

% get name of test
name_of_test = inputdlg('What is the name of this test?');

% check and parse
if ~isempty(name_of_test)
    name_of_exp = name_of_test{1};
else
    error('Please input name for the experiment');
end

% get csv data file

if exist('/groups/sutphin/_Data','dir')
    [file,path]  = uigetfile('/groups/sutphin/_Data/*.csv','Please select the data file');
else
    [file,path] = uigetfile('*.csv','Please select the data file');
end


if ~isempty(file)
    data = readtable(fullfile(path,file),...
        'VariableNamingRule','preserve');
else
    error('Please give the .csv for the experiment');
end

% get data
condition_cell = [data.Dosage, data.Strain];
condition_comb = strings(1,length(condition_cell));

% combine the strings
for i = 1:length(condition_cell)
    condition_comb(i) = string([condition_cell{i,1} ' -- ' condition_cell{i,2}]);
end

% reference for all the conditions
all_cond = unique(condition_comb);

all_cond_cell = cell(1,length(all_cond));
for i = 1:length(all_cond)
    all_cond_cell{i} = char(all_cond(i));
end

[~,natsort_idx,~] = natsort(all_cond_cell);

all_cond = all_cond(natsort_idx);

% select the conditions that you want
[choice_idx,tf] = listdlg('ListString',all_cond);

if isempty(choice_idx)
    error('Please choose at least one condition')
end

% if you are not combining everything
% then get the control for that experiment
if ~combine_everything_into_one
    [control_indx,tf] = listdlg('PromptString',{'Select the Control.',...
        'Only one Control can be selected.',''},...
        'SelectionMode','single','ListString',all_cond(choice_idx));
    
    temp_choice = choice_idx(control_indx);
    
    choice_idx(control_indx) = [];
    
    choice_idx = [temp_choice, choice_idx];
end

% isolate the conditions from all the conditions
conditions_to_isolate = all_cond(choice_idx);

% regular not combinatorial
if ~combine_everything_into_one
    
    % set up variables
    keep_idx = cell(1,length(conditions_to_isolate));
    sep_exps_days = cell(1,length(conditions_to_isolate));
    sep_exps_days_health = cell(1,length(conditions_to_isolate));
    censored_wells_any_separated = cell(1,length(conditions_to_isolate));
    legend_names = cell(1,length(conditions_to_isolate));
    legend_names_health = cell(1,length(conditions_to_isolate));
    median_lifespans = zeros(1,length(conditions_to_isolate));
    median_healthspans = zeros(1,length(conditions_to_isolate));
    N = zeros(1,length(conditions_to_isolate));
    
    % isolate the ones that you want
    % and other associated variables
    
    for i = 1:length(conditions_to_isolate)
        % find specific idx that represent that condition
        keep_idx{i} = (condition_comb == conditions_to_isolate(i));
        
        % get life and healthspan from dataset
        sep_exps_days{i} = data.("Last day of observation")(keep_idx{i});
        sep_exps_days_health{i} = data.("Last day of health")(keep_idx{i});
        
        % get the censors
        censored_wells_any_separated{i} = [data.("Manual Censor")(keep_idx{i}) | ...
            data.("Runoff Censor experiment")(keep_idx{i}) | ...
            data.("Runoff Censor inital")(keep_idx{i})];
        
        % get the median life and healthspans
        median_lifespans(i) = median(...
            nonzeros(sep_exps_days{i}.*(~censored_wells_any_separated{i})));
        median_healthspans(i) = median(...
            nonzeros(sep_exps_days_health{i}.*(~censored_wells_any_separated{i})));
        
        % get the total N values
        N(i) = sum(keep_idx{i}); % - sum(censored_wells_any_separated{i});
        
        % get legend names lifepsan
        legend_names{i} = [conditions_to_isolate{i} ...
            ' | median lifespan: ' num2str(median_lifespans(i)) ...
            ' | N=' num2str(N(i))];
        
        % get legend names healthspan
        legend_names_health{i} = [conditions_to_isolate{i} ...
            ' | median healthspan: ' num2str(median_healthspans(i)) ...
            ' | N=' num2str(N(i))];
        
    end
else
    
    % this is for comparing single conditions across experiments
    
    % set up variables
    % set up variables
    keep_idx = cell(1,length(conditions_to_isolate)+1);
    sep_exps_days = cell(1,length(conditions_to_isolate)+1);
    sep_exps_days_health = cell(1,length(conditions_to_isolate)+1);
    censored_wells_any_separated = cell(1,length(conditions_to_isolate)+1);
    legend_names = cell(1);
    legend_names_health = cell(1);
    median_lifespans = zeros(1);
    median_healthspans = zeros(1);
    N = zeros(1);
    
    % isolate the ones that you want
    % and other associated variables
    
    keep_idx_temp = zeros(1,height(data));
    
    for i = 1:length(conditions_to_isolate)
        keep_idx_temp = keep_idx_temp + (condition_comb == conditions_to_isolate(i));
    end
    
    % conbine the keep idx
    keep_idx_final{1} = logical(keep_idx_temp);
    
    % rename the conditions to the name of the test
    conditions_to_isolate_comb = name_of_test;
    
    for i = 1:length(conditions_to_isolate)
        % find specific idx that represent that condition
        keep_idx{i} = (condition_comb == conditions_to_isolate(i));
        
        % get life and healthspan from dataset
        sep_exps_days{i} = data.("Last day of observation")(keep_idx{i});
        sep_exps_days_health{i} = data.("Last day of health")(keep_idx{i});
        
        % get the censors
        censored_wells_any_separated{i} = [data.("Manual Censor")(keep_idx{i}) | ...
            data.("Runoff Censor experiment")(keep_idx{i}) | ...
            data.("Runoff Censor inital")(keep_idx{i})];
        
    end
    
    i = 1;
    
    % get all the data as a pooled set
    sep_exps_days{end} = data.("Last day of observation")(keep_idx_final{1});
    sep_exps_days_health{end} = data.("Last day of health")(keep_idx_final{1});
    
    censored_wells_any_separated{end} = [data.("Manual Censor")(keep_idx_final{1}) | ...
        data.("Runoff Censor experiment")(keep_idx_final{1}) | ...
        data.("Runoff Censor inital")(keep_idx_final{1})];
    
    % get the median life and healthspans
    median_lifespans(i) = median(...
        nonzeros(sep_exps_days{end}.*(~censored_wells_any_separated{end})));
    median_healthspans(i) = median(...
        nonzeros(sep_exps_days_health{end}.*(~censored_wells_any_separated{end})));
    
    N(i) = sum(keep_idx_final{i}); % - sum(censored_wells_any_separated{i});
    
    legend_names{i} = [conditions_to_isolate_comb{i} ...
        ' | median lifespan: ' num2str(median_lifespans(i)) ...
        ' | N=' num2str(N(i))];
    
    legend_names_health{i} = [conditions_to_isolate_comb{i} ...
        ' | median healthspan: ' num2str(median_healthspans(i)) ...
        ' | N=' num2str(N(i))];
    
end

% find the maximum number of days survived from the entire experiment
max_days = max(cellfun(@max,sep_exps_days));


if ~combine_everything_into_one
    % plot the lifespan survival curves
    plot_survival_curve_life(conditions_to_isolate,...
        sep_exps_days,censored_wells_any_separated,legend_names,...
        max_days,name_of_exp,use_markers,use_title)
    
    % plot the healthspan survival curves
    plot_survival_curve_health(conditions_to_isolate,...
        sep_exps_days_health,censored_wells_any_separated,legend_names_health,...
        max_days,name_of_exp,use_markers,use_title)
else
    % plot the lifespan survival curves
    plot_survival_curve_life_combine(conditions_to_isolate,...
        sep_exps_days,censored_wells_any_separated,legend_names,...
        max_days,name_of_exp,use_markers,use_title);
    
    % plot the healthspan survival curves
    plot_survival_curve_health_combine(conditions_to_isolate,...
        sep_exps_days_health,censored_wells_any_separated,legend_names_health,...
        max_days,name_of_exp,use_markers,use_title);
end

out_folder_life = fullfile(pwd,'output_figures',[name_of_test{1} '_lifespan.png']);
out_folder_health = fullfile(pwd,'output_figures',[name_of_test{1} '_healthspan.png']);

if ispc
    cmd_command_life = ['explorer /select, ' out_folder_life];
    system(cmd_command_life)

else
    out_folder_life = replace(out_folder_life,' ', '\ ');
    out_folder_health = replace(out_folder_health,' ', '\ ');
    
    terminal_command_life = ['gio open ' out_folder_life];
    system(terminal_command_life);
    
end


function plot_survival_curve_life(conditions,days_survived,censor,...
    legend_names,max_days,name_of_exp,use_markers,use_title)

% This is an un-elegant solution for the problem that you cant just
% plot many different lines without them all being the same color and style
all_marks = {'o','+','*','.','x','s','d','^','p','h','o','+','*',...
    '.','x','s','d','^','p','h','o','+','*','.','x','s','d','^',...
    'p','h','o','+','*','.','x','s','d','^','p','h'};
all_colors = {'k','r','b','g','m','c','y','r','g','b','k','m','c'...
    ,'r','g','b','k','y','m','c','r','g','b','k','r','g','b','k','m'...
    ,'c','r','g','b','k','y','m','c','r','g','b','k','y','m','c','r','g','b','k'};

% create the fullscreen figure
g = figure('units','normalized','outerposition',[0 0 1 1]);
% increase the axis font size
axes('FontSize',20)
% make sure the graph is square
axis square
hold on
for i = 1:length(conditions)
    % get the ecdf survival curves
    [this_survival_curve,x] = ecdf(days_survived{i},...
        'censoring',censor{i},'function','survivor');
    
    % plot the specific curve with colors and sizes
    if use_markers
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color',all_colors{i},'Marker',all_marks{i},'MarkerSize',10)
    else
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color',all_colors{i})
    end
end

% labels and legends
if use_title
    title(['Combined lifespans for ' name_of_exp],'Interpreter','none','FontSize',24);
end
ylabel('Fraction remaining','FontSize',20,'FontWeight','bold')
xlabel('Days from adulthood','FontSize',20,'FontWeight','bold');
xlim([0,max_days+2])
xticks([0:5:max_days+2])
legend(legend_names, 'interpreter','none','FontSize',15);

% save to a folder in output_figures
mkdir('output_figures')

saveas(g,char([pwd '/output_figures/' name_of_exp '_lifespan.png']))

hold off


end

function plot_survival_curve_health(conditions,days_survived,censor,...
    legend_names,max_days,name_of_exp,use_markers,use_title)

% see plot_survival_curve_life for detailed notes

all_marks = {'o','+','*','.','x','s','d','^','p','h','o','+','*',...
    '.','x','s','d','^','p','h','o','+','*','.','x','s','d','^',...
    'p','h','o','+','*','.','x','s','d','^','p','h'};
all_colors = {'k','r','b','g','m','c','y','r','g','b','k','m','c'...
    ,'r','g','b','k','y','m','c','r','g','b','k','r','g','b','k','m'...
    ,'c','r','g','b','k','y','m','c','r','g','b','k','y','m','c','r','g','b','k'};

g = figure('units','normalized','outerposition',[0 0 1 1]);
axes('FontSize',20)
axis square
hold on
for i = 1:length(conditions)
    [this_survival_curve,x] = ecdf(days_survived{i},...
        'censoring',censor{i},'function','survivor');
    if use_markers
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color',all_colors{i},'Marker',all_marks{i},'MarkerSize',10)
    else
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color',all_colors{i})
    end
end

if use_title
    title(['Combined healthspans for ' name_of_exp],'Interpreter','none','FontSize',24);
end
ylabel('Fraction healthy','FontSize',20,'FontWeight','bold');
xlabel('Days healthy from adulthood','FontSize',20,'FontWeight','bold');
xlim([0,max_days+2])
xticks([0:5:max_days+2])
legend(legend_names, 'interpreter','none','FontSize',15);

saveas(g,char([pwd '/output_figures/' name_of_exp '_healthspan.png']))

hold off


end




function [g] = plot_survival_curve_life_combine(conditions,days_survived,censor,...
    legend_names,max_days,name_of_exp,use_markers,use_title)

% This is an un-elegant solution for the problem that you cant just
% plot many different lines without them all being the same color and style

% create the fullscreen figure
g = figure('units','normalized','outerposition',[0 0 1 1]);
% increase the axis font size
axes('FontSize',20)
% make sure the graph is square
axis square
hold on
for i = 1:length(conditions)
    % get the ecdf survival curves
    [this_survival_curve,x] = ecdf(days_survived{i},...
        'censoring',censor{i},'function','survivor');
    
    % plot the specific curve with colors and sizes
    
    if isequal(i,length(conditions))
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color','k')
    else
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color',[0.5,0.5,0.5,0.2])
    end
end

% labels and legends
if use_title
    title(['Combined lifespans for ' name_of_exp],'Interpreter','none','FontSize',24);
end
ylabel('Fraction remaining','FontSize',20,'FontWeight','bold')
xlabel('Days from adulthood','FontSize',20,'FontWeight','bold');
xlim([0,max_days+2])
xticks([0:5:max_days+2])
legend(legend_names, 'interpreter','none','FontSize',15);

% save to a folder in output_figures
mkdir('output_figures')

saveas(g,char(fullfile(pwd,'output_figures',[name_of_exp '_lifespan.png'])));

hold off


end

function plot_survival_curve_health_combine(conditions,days_survived,censor,...
    legend_names,max_days,name_of_exp,use_markers,use_title)

% see plot_survival_curve_life for detailed notes

g = figure('units','normalized','outerposition',[0 0 1 1]);

axes('FontSize',20)
axis square
hold on
for i = 1:length(conditions)
    [this_survival_curve,x] = ecdf(days_survived{i},...
        'censoring',censor{i},'function','survivor');
    
    if isequal(i,length(conditions))
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color','k')
    else
        plot(x,this_survival_curve,...
            'LineStyle','-','LineWidth',5,...
            'Color',[0.5,0.5,0.5,0.2])
    end
end

if use_title
    title(['Combined healthspans for ' name_of_exp],'Interpreter','none','FontSize',24);
end
ylabel('Fraction healthy','FontSize',20,'FontWeight','bold');
xlabel('Days healthy from adulthood','FontSize',20,'FontWeight','bold');
xlim([0,max_days+2])
xticks([0:5:max_days+2])
legend(legend_names, 'interpreter','none','FontSize',15);

saveas(g,char(fullfile(pwd,'output_figures',[name_of_exp '_healthspan.png'])));

hold off


end






