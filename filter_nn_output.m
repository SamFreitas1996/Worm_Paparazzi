function [output] = filter_nn_output(output,error_message,sess_nums,nn_confidence_thresh)

output2 = output;

output_cells = cell(1,length(output));
centers = cell(1,length(output));

num_days = length(sess_nums);

for i = 1:length(output_cells)
    output_cells{i} = output(i,:);
    
    this_output = output(i,:);
    
    if this_output(end)>nn_confidence_thresh
        this_center = [mean([this_output(2),this_output(4)]),mean([this_output(3),this_output(5)])];
    else
        this_center = [0,0];
    end
    
    if sum(this_center < 10) || sum(this_center > 205-10)
        this_center = [0,0];
    end
    
    centers{i} = this_center;
    
end

centers_reshape = flip(rot90(reshape(centers,[length(sess_nums),240]),3),2);
zero_zero_scrub_counter = 1;

for i = 1:240
    
    these_centers = centers_reshape(i,:);
    these_centers2 = centers_reshape(i,:);
    zero_idx = zeros(1,length(these_centers));
    for j = 1:length(these_centers)
        
        if isequal(these_centers{j},[0,0])
            zero_idx(j) = 1;
            output2(zero_zero_scrub_counter,6) = 0;
        end
        
        zero_zero_scrub_counter = zero_zero_scrub_counter + 1;
        
    end
    these_centers = these_centers(~zero_idx);
    
    bad_idx = zeros(1,length(these_centers));
    for j = length(these_centers):-1:2
        this_dist = norm(these_centers{j}-these_centers{j-1});
        
        if this_dist < 50
            bad_idx(j) = 1;
        end
        
    end
    
    these_centers = these_centers(~bad_idx);
    
    last_good_idx = num_days;
    if ~(isempty(these_centers))
        last_center = these_centers{end};
        for j = length(these_centers2):-1:1
            if isequal(last_center,these_centers2{j})
                last_good_idx = j;
                break
            end
        end
    end
    
    if i<239
        scrub_idx = (((i-1)*num_days)+last_good_idx):(i*num_days);
    else
        scrub_idx = (((i-1)*num_days)+last_good_idx):length(output);
    end
    
    output2(scrub_idx,6) = 0;
    
end

output = output2;

for i = 1:240
    these_centers = centers_reshape(i,:);
    boolean_if_worm = zeros(1,length(these_centers));
    
    for j = 1:length(these_centers)
        boolean_if_worm(j) = sum(these_centers{j})>0;
    end
    
    boolean_if_worm = [boolean_if_worm 0 0 0 0 0];
    
    boolean_no_worm = ~boolean_if_worm;
    
    for j = 1:length(boolean_no_worm)
        
        % if there are not 5 days of worms in a row
        if sum(boolean_no_worm(j:j+4)) == 5
            last_good_idx = j;
            break
        end
        
    end
    
    if i<239
        scrub_idx = (((i-1)*num_days)+last_good_idx):(i*num_days);
    else
        scrub_idx = (((i-1)*num_days)+last_good_idx):length(output);
    end
    
    output2(scrub_idx,6) = 0;
    
end

output = output2;

end
