% runoff_health_life

% 
load('setup.mat');


potential_healthspans_days = zeros(1,240);


for i = 1:240
    
    this_nn_predict = worms_nn_predicted(i,:)>.75;
    
    this_health = find(this_nn_predict==1,1,'last');
    
    if ~isempty(this_health)
        potential_healthspans_days(i) = this_health + 1 ;
    end
    
end

inital_runoff = ~logical(sum(worms_nn_predicted>.75,2));

health_life_diff = abs(potential_lifespans_days-potential_healthspans_days);
experimental_runoff = zeros(size(inital_runoff));

for i = 1:240
    
    if ~inital_runoff(i)
        if health_life_diff(i)<2
            experimental_runoff(i) = 1;
        end
    end
end
experimental_runoff = logical(experimental_runoff);
