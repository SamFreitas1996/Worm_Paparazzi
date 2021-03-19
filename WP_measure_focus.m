% measure focus level


function [focus_measure] = WP_measure_focus(stack,rad_pixels,create_figure,title_figure)

if rad_pixels == 0
    rad_pixels = 250;
end

[r,c]=size(stack{1});
r_center = round(r/2);
c_center = round(c/2);

xo = r_center-rad_pixels;
yo = c_center-rad_pixels;
w = rad_pixels*2;
h = rad_pixels*2;

% take only a specific amount of pixels from the center of the image
f_roi = [xo yo w h];

focus_measure = zeros(1,length(stack));

for i = 1:length(stack)
    focus_measure(i) = double(fmeasure(stack{i}, 'VOLA' , f_roi));
end

focus_measure = focus_measure/max(focus_measure);

if create_figure
    figure;
    plot(focus_measure)
    title(title_figure);
    drawnow
end


end