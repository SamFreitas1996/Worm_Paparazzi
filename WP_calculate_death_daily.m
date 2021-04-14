% WP calculate potential deaths

function [potential_lifespans_days, potential_lifespans_sess,worms_not_dead,data_points_to_omit] = ...
    WP_calculate_death_daily(raw_sess_data_aft, raw_sess_data_bef, raw_sess_data_integral,censored_wells,...
    raw_sess_data_aft_bw,raw_sess_data_bef_bw,...
    export_data,this_exp_num,runoff_cutoff,data_storage,min_activity,sess_activity_buffer,sess_nums,exp_nm,num_days,bw_analysis)


% find the median activity number for every day
% it should be zero for any day without noise and that is after the
% runoff_cutoff period
median_norm_data = median(raw_sess_data_integral,2)+1;

% everything before the runoff cutoff gets converted to a 1 so the division
% does not completely mess with the datasets
median_norm_data2 = median_norm_data;
median_norm_data2(1:runoff_cutoff)=1;

% find the incorrect data points
data_points_to_omit = find_badly_registered_sessions(data_storage);

if ~isempty(data_points_to_omit)
    disp(['Sessions: ' num2str(data_points_to_omit') ' Are badly registered and are skipped']);
end

% normalize the raw session data to the median to reduce the peak noise
% from random sessions
raw_norm_curves = raw_sess_data_integral./repmat(median_norm_data2,1,240);

save(char([data_storage '/processed_data/norm_activity']),'raw_sess_data_integral','raw_sess_data_bef','raw_sess_data_aft','raw_norm_curves','median_norm_data2','censored_wells','raw_sess_data_aft_bw','raw_sess_data_bef_bw')

% initalize variables
% % % % potential_lifespans_days=gpuArray(zeros(1,240));
% % % % potential_lifespans_sess=gpuArray(zeros(1,240));

potential_lifespans_days=(zeros(1,240));
potential_lifespans_sess=(zeros(1,240));

worms_not_dead = (zeros(1,240));

if bw_analysis
    % changed 2/22/21 to + not -
    bw_diff = (raw_sess_data_aft_bw+raw_sess_data_bef_bw);
    
    for i = 1:240
        
        this_worm_bw = abs(bw_diff(:,i));
        
        try
            this_worm_bw(data_points_to_omit) = 0;
        catch
            disp('ererere');
        end
        
        this_worm_bw2 = NaN(size(sess_nums));
        for j = 1:length(this_worm_bw)
            [a,b] = find(sess_nums == j);
            this_worm_bw2(a,b) = this_worm_bw(j);
        end
        this_worm_bw2 = mean(this_worm_bw2,2,'omitnan');
        
        % fill 24 hour holes
        for j = 2:length(this_worm_bw2)-1
            
            if this_worm_bw2(j-1)>0 && this_worm_bw2(j+1)>0 && this_worm_bw2(j)==0
                this_worm_bw2(j) = mean([this_worm_bw2(j-1),this_worm_bw2(j+1)]);
            end
            
        end
        
        % find where the frst zero happens
        this_death_bw_first = find(this_worm_bw2==0,1,'first');
        
        % find where the last non zero happens 
        this_death_bw_last = find(this_worm_bw2>0,1,'last')+1;
        
        if ~isequal(this_death_bw_first,this_death_bw_last)
            this_death_bw = find(medfilt1(this_worm_bw2,3)==0,1,'first');
        else
            this_death_bw = this_death_bw_first;
        end
        
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
    
    
else
    % use regular analysis not BW
    
    for i = 1:240
        
        % only calcualte if this isnt manually censored
        if ~censored_wells(i)
            
            % temp worm
            thisWorm = raw_sess_data_integral(:,i);
            
            % initilize a temp variable
            pot_death_sessions = 1:length(thisWorm);
            
            % find whenever the unique worm is over the specific minimum
            % activity, this shouldnt be too high, but it should be large
            % enough to cancel out a lot of the noise,
            pot_death_sessions=pot_death_sessions(thisWorm>min_activity);
            
            % iterate backwards from the final sessions that will be calculated
            % as its "death session"
            % if there is a session within 5 sessions before it that is also a
            % movement thresholded, then it is correct
            for j = length(pot_death_sessions):-1:2
                if (pot_death_sessions(j)-pot_death_sessions(j-1))>sess_activity_buffer
                    pot_death_sessions(j)=[];
                end
            end
            
            % record the session unless its empty
            if ~isempty(pot_death_sessions)
                potential_lifespans_sess(i)=pot_death_sessions(end);
                
                if pot_death_sessions(end)==length(thisWorm)
                    %                 potential_lifespans_sess(i)=0;
                    % %                 disp(['worm ' num2str(i) ' has messy data'])
                    
                    worms_not_dead(i) = 1;
                    
                end
            else
                potential_lifespans_sess(i)=0;
            end
            
            
            
            % convert it to number of days on the robot only if the days exist
            % (not zero)
            
            if potential_lifespans_sess(i)
                [potent_days,potent_sess_num]=(find(potential_lifespans_sess(i)==sess_nums));
                
                potential_lifespans_days(i) = potent_days + (potent_sess_num-1)*.33;
            end
            
        end
        
    end
end

disp([data_storage ' has ' num2str(sum(worms_not_dead>0)) ' worms either not dead or messy data']);

disp('Saving processed data');

potential_lifespans_days=gather(potential_lifespans_sess);
potential_lifespans_sess=gather(potential_lifespans_sess);
try
    save(char([data_storage '/processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','worms_not_dead','-append')
catch
    save(char([data_storage '/processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','worms_not_dead')
    save(char([data_storage '/processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','worms_not_dead','-append')
end



end


function data_points_to_omit = find_badly_registered_sessions(data_storage)

imgs_path = [data_storage '/processed_data'];

imgs_dir = dir(fullfile(imgs_path,'*.png'));

[Y,ndx,dbg] = natsort({imgs_dir.name});

imgs_dir = imgs_dir(ndx);

for i = 1:length(imgs_dir)
    
    A = imread(fullfile(imgs_dir(i).folder,imgs_dir(i).name));
    
    b(i) = sum(A(:));
    
end

sess_vector = 1:length(imgs_dir);

bad_data = b>(1*10^8);

data_points_to_omit = nonzeros(bad_data.*sess_vector);


end