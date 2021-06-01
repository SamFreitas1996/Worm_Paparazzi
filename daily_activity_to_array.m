function out_array = daily_activity_to_array(worm_daily_activity)


max_days = zeros(1,length(worm_daily_activity));

for i = 1:length(worm_daily_activity)
    max_days(i) = max(cellfun(@length,worm_daily_activity{i}));
end

total_max_day = max(max_days);

num_worms = sum(cellfun(@length,worm_daily_activity));

daily_activity = zeros(num_worms,total_max_day);

k=1;
for i = 1:length(worm_daily_activity)
    
    for j = 1:length(worm_daily_activity{i})
        daily_activity(k,1:length(worm_daily_activity{i}{j})) = worm_daily_activity{i}{j};
        k=k+1;
    end
    
end

out_array = daily_activity;

end