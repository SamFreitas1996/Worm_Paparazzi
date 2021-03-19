% WP calculate potential deaths

function [potential_lifespans_days, potential_lifespans_sess,worms_not_dead] = ...
    WP_calculate_death(raw_sess_data_aft, raw_sess_data_bef, raw_sess_data_integral,censored_wells,...
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
    
    bw_diff = (raw_sess_data_aft_bw-raw_sess_data_bef_bw);
    
    for i = 1:240
        
        this_worm_bw = abs(bw_diff(:,i));
        for j = 2:length(this_worm_bw)-2
            
            if this_worm_bw(j-1)>0 && this_worm_bw(j+1)>0 && this_worm_bw(j)==0
                
                this_worm_bw(j) = mean([this_worm_bw(j-1),this_worm_bw(j+1)]);
            end
            if this_worm_bw(j-1)<0 && this_worm_bw(j+1)<0 && this_worm_bw(j)==0
                
                this_worm_bw(j) = mean([this_worm_bw(j-1),this_worm_bw(j+1)]);
            end
            
            if this_worm_bw(j)==0 && this_worm_bw(j+1)==0 && this_worm_bw(j+2)>0
                this_worm_bw(j:j+1)=1;
            end
            
        end
        
        for j = 2:length(this_worm_bw)-2
            
            if this_worm_bw(j) == 0 && (this_worm_bw(j-1)>0 && this_worm_bw(j+1)>0)
                this_worm_bw(j) = 1;
            end
            
        end
        
        
        if (this_worm_bw(1)==0 && this_worm_bw(2)>0) || (this_worm_bw(1)==0 && this_worm_bw(2)==0 && this_worm_bw(3)>0)
            this_worm_bw(1:3)=(this_worm_bw(1:3)+1);
        end
        
        % find where the frst zero happens
        this_death_bw = find(this_worm_bw==0,1,'first');
        
        % if there is a found zero record its death 
        if ~isempty(this_death_bw)
            potential_lifespans_sess(i) = this_death_bw;
            
            if this_death_bw==length(this_worm_bw)
                %                 potential_lifespans_sess(i)=0;
                % %                 disp(['worm ' num2str(i) ' has messy data'])
                
                worms_not_dead(i) = 1;
                
            end
        else
            % if there isnt a zero the worm is most likley alive 
            potential_lifespans_sess(i)=length(this_worm_bw);
            worms_not_dead(i) = 1;
        end
        
        % if there is a potential lifespan, then convert from session to
        % days
        if potential_lifespans_sess(i)
            [potent_days,potent_sess_num]=(find(potential_lifespans_sess(i)==sess_nums));
            
            potential_lifespans_days(i) = potent_days + (potent_sess_num-1)*.33;
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

potential_lifespans_days=gather(potential_lifespans_days);
potential_lifespans_sess=gather(potential_lifespans_sess);
save(char([data_storage '/processed_data/potential_lifespans']),'potential_lifespans_days','potential_lifespans_sess','worms_not_dead')




end