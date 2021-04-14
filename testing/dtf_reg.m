% dtf registration of images
% (image_to_reg,template_img,usfac,rad_pixels)

function [output_img] = dtf_reg(image_to_reg,template_img,usfac,rad_pixels)

f = template_img;
g = image_to_reg;
[r,c]=size(f);

if usfac == 0
    usfac = 1;
end

if rad_pixels == 0
    rad_pixels = 250;
end

% take only a specific amount of pixels from the center of the image
f_roi = f((r/2)-rad_pixels:(r/2)+rad_pixels,(c/2)-rad_pixels:(c/2)+rad_pixels);
g_roi = g((r/2)-rad_pixels:(r/2)+rad_pixels,(c/2)-rad_pixels:(c/2)+rad_pixels);

% quickly register the two smaller images
[output, ~] = dftregistration(fft2(f_roi),fft2(g_roi),usfac);

% output=[error,diffphase,row_shift,col_shift];
error_amount = output(1);
diffphase = output(2);
row_shift = output(3);
col_shift = output(4);

% use the row and column shift to transform the two large images
buf2ft=fft2(g);
[nr,nc]=size(buf2ft);
Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
[Nc,Nr] = meshgrid(Nc,Nr);
Greg = buf2ft.*exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
Greg = Greg*exp(1i*diffphase);

output_img = abs(ifft2(Greg));


end