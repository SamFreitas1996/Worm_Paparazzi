# testing multithreading 

import time
import threading
import numpy as np
import random

global result

result = dict()

def calc_square(i):
   # print("Calculate square numbers: ")
   time.sleep(random.uniform(0, 1))   #artificial time-delay
   temp = i*i
   result.update({i:temp})

arr = np.arange(40)+1

t = time.time()

tt = []
for i in range(40):
   tt.append(threading.Thread(target = calc_square,args=(arr[i],)))

for i in range(40):
   tt[i].start()

for i in range(40):
   tt[i].join()

print(result)
for key in sorted(result):
   print(result[key])
