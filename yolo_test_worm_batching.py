import torch
import os
import sys
import shutil
from PIL import Image
import glob
import numpy as np
import matplotlib.pyplot as plt
import time
from natsort import natsorted

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
model = torch.hub.load('ultralytics/yolov5', 'custom', path_or_model='best_worms2 (5).pt',verbose=False)

model.eval()
# model = torch.hub.load('ultralytics/yolov5', 'yolov5s')

# py detect.py --weights best4.pt --img 1824 --conf 0.85 --source .\data\images\ --save-txt --save-conf 

path_to_img_dir = os.path.join('temp_imgs','*.jpg')
img_file_paths = natsorted(glob.glob(path_to_img_dir))

num_batches = 15

img_file_paths_batching = np.array_split(img_file_paths,num_batches)

model.conf = 0.4

model.to(torch.device('cpu'))

all_results = []

for count, this_path_batch in enumerate(img_file_paths_batching):
    print('Running batch: ', count)

    imgs = []
    img_names = []
    for count, filename in enumerate(this_path_batch): #assuming gif
        # print('Opening image: ', filename)
        base = os.path.basename(filename)
        img_names.append(os.path.splitext(base)[0])
        im=Image.open(filename)
        imgs.append(im)

    elapsed = time.time() - t
    print('image reading:', elapsed)

    print('running neural network')
    results = model(imgs, size=192)  # custom inference size

    results.name = ['']

    # # Data
    # print(results.xyxy[0])  # print img1 predictions (pixels)
    # #                   x1           y1           x2           y2   confidence        class
    # # tensor([[7.50637e+02, 4.37279e+01, 1.15887e+03, 7.08682e+02, 8.18137e-01, 0.00000e+00],
    # #         [9.33597e+01, 2.07387e+02, 1.04737e+03, 7.10224e+02, 5.78011e-01, 0.00000e+00],
    # #         [4.24503e+02, 4.29092e+02, 5.16300e+02, 7.16425e+02, 5.68713e-01, 2.70000e+01]])

    # results.save()

    print('exporting data')

    for count,this_img_name in enumerate(img_names):
        

        this_results = np.asarray(results.xyxy[count].cpu())
        # this_results = np.asarray(results.xywh[count].cpu())

        if this_results.any():
            a = np.zeros(shape=(6,))
            a[0] = this_img_name
            a[1] = round(np.min(this_results[:,0]))
            a[2] = round(np.min(this_results[:,1]))
            a[3] = round(np.max(this_results[:,2]))
            a[4] = round(np.max(this_results[:,3]))
            a[5] = np.mean(this_results[:,4])
        if not this_results.any():
            a = np.zeros(shape=(6,))
            a[0] = this_img_name

        all_results.append(a)

txt_output_path = os.path.join(os.getcwd(),'results','output_array' + '.csv')
np.savetxt(txt_output_path, all_results, delimiter=",")

elapsed = time.time() - t
print('NN running:', round(elapsed/60,1), ' minutes')

