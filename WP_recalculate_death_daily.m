% this function takes the healthspans and recalculates the lifespan calls
% with the new data

function [potential_lifespans_days, potential_lifespans_sess,worms_not_dead,potential_healthspans_days] = ...
    WP_recalculate_death_daily...
    (data_storage,exp_nm,sess_nums,final_data_export_path,full_exp_name,worms_not_dead)

% ignore these warnings 
load([data_storage '/processed_data/norm_activity']);
load([data_storage '/processed_data/potential_lifespans']);
load([data_storage '/processed_data/runoff_worms']);
clear median_norm_data2 raw_norm_curves

sess_diff = abs(raw_sess_data_aft_bw-raw_sess_data_bef_bw);

l_day = ~(censored_wells_runoff_nn|censored_wells_runoff_var).*(potential_lifespans_days);
h_day = ~(censored_wells_runoff_nn|censored_wells_runoff_var).*(potential_healthspans_days);

idx = [];
for i = 1:240
    
    if h_day(i) > l_day(i)
        
        idx = [idx i];
    end
end

l_day = ~(censored_wells_runoff_nn|censored_wells_runoff_var).*(potential_lifespans_days);
h_day = ~(censored_wells_runoff_nn|censored_wells_runoff_var).*(potential_healthspans_days);

for i = idx
    
    
    this_worm_bw = sess_diff(:,i);
    this_worm_int = raw_sess_data_integral(:,i);
    
    this_worm_bw2 = NaN(size(sess_nums));
    this_worm_int2 = this_worm_bw2;
    for j = 1:length(this_worm_bw)
        [a,b] = find(sess_nums == j);
        this_worm_bw2(a,b) = this_worm_bw(j);
        this_worm_int2(a,b) = this_worm_int(j);
    end
    this_worm_bw2 = mean(this_worm_bw2,2,'omitnan');
    this_worm_int2 = mean(this_worm_int2,2,'omitnan');
    
    % fill 24 hour holes
    for j = 2:length(this_worm_bw2)-1
        
        if this_worm_bw2(j-1)>0 && this_worm_bw2(j+1)>0 && this_worm_bw2(j)==0
            this_worm_bw2(j) = mean([this_worm_bw2(j-1),this_worm_bw2(j+1)]);
        end
        
    end
    
    % to fill the gaps between the healthy potential lifespan call
    gap_fill = h_day(i);
        
    try
        this_worm_bw2(1:gap_fill) = this_worm_bw2(1:gap_fill)+1;
    catch
        gap_fill = length(this_worm_bw2);
        
        this_worm_bw2(1:gap_fill) = this_worm_bw2(1:gap_fill)+1;
    end
    
    this_death_bw = find(this_worm_bw2==0,1,'first');
%     
%     figure;
%     x = 1:length(this_worm_bw2);
%     plot(x,this_worm_bw2/max(this_worm_bw2),'b-',x,this_worm_int2/max(this_worm_int2),'b--',...
%         l_day(i),0,'r*',this_death_bw,0,'ro',h_day(i),0,'g*');
%     title(i)
    
% if there is a found zero record its death
    if ~isempty(this_death_bw)
        potential_lifespans_days(i) = this_death_bw;

        % if the death is the same length as the data then its still
        % alive
        if this_death_bw==length(this_worm_bw2)
            worms_not_dead(i) = 1;
        end
    else
        % if there isnt a zero the worm is most likley alive
        potential_lifespans_days(i)=length(this_worm_bw2);
        worms_not_dead(i) = 1;
    end

    % if there is a potential lifespan, then convert from days to
    % sessions (reports days)
    if potential_lifespans_days(i)
        potential_lifespans_sess(i) = potential_lifespans_days(i);

    end
    
end

save(char([data_storage 'processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','potential_healthspans_days','-append');
f_out = fullfile(final_data_export_path,full_exp_name,[exp_nm '-data.mat']);
save(char(f_out),'potential_lifespans_days','potential_lifespans_sess','potential_healthspans_days','-append');

end