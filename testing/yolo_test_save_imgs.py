import torch
import os
import sys
import shutil
from PIL import Image
import glob
import numpy as np
import matplotlib.pyplot as plt
import time

# try to make the results folder
# if it already exists then delete it and make a new one
try:
    os.mkdir('results')
except:
    shutil.rmtree('results')
    os.mkdir('results')

t = time.time()
elapsed = time.time() - t
print('Dir creation:', elapsed)
# load in the 
model = torch.hub.load('ultralytics/yolov5', 'custom', path_or_model='WPdata_weights.pt')
# py detect.py --weights best4.pt --img 1824 --conf 0.85 --source .\data\images\ --save-txt --save-conf 

img_file_paths = glob.glob('temp_imgs/*.jpg')

imgs = []
img_names = []
for filename in img_file_paths: #assuming gif
    # print('Opening image: ', filename)
    base = os.path.basename(filename)
    img_names.append(os.path.splitext(base)[0])
    im=Image.open(filename)
    imgs.append(im)

model.conf = 0.5

elapsed = time.time() - t
print('image reading:', elapsed)

print('running neural network')
results = model(imgs, size=704)  # custom inference size

# # Data
# print(results.xyxy[0])  # print img1 predictions (pixels)
# #                   x1           y1           x2           y2   confidence        class
# # tensor([[7.50637e+02, 4.37279e+01, 1.15887e+03, 7.08682e+02, 8.18137e-01, 0.00000e+00],
# #         [9.33597e+01, 2.07387e+02, 1.04737e+03, 7.10224e+02, 5.78011e-01, 0.00000e+00],
# #         [4.24503e+02, 4.29092e+02, 5.16300e+02, 7.16425e+02, 5.68713e-01, 2.70000e+01]])


elapsed = time.time() - t
print('NN running:', elapsed)

print('exporting data v1')

results.save()

for count,this_img_name in enumerate(img_names):
    txt_output_path = os.path.join(os.getcwd(),'results',this_img_name + '.csv')

    this_results = np.asarray(results.xywh[count].cpu())

    np.savetxt(txt_output_path, this_results, delimiter=",")

print('end')

