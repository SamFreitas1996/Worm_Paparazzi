import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3' 
# import matplotlib.pyplot as plt
import numpy as np
import PIL
from natsort import natsorted
from matplotlib import image

import tensorflow as tf

from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.models import Sequential
import pathlib


# dataset_url = "https://storage.googleapis.com/download.tensorflow.org/example_images/flower_photos.tgz"
# data_dir = tf.keras.utils.get_file('flower_photos', origin=dataset_url, untar=True)
# data_dir = pathlib.Path(data_dir)
data_dir2 = pathlib.Path('E:\Codes\TFWP_training')
# image_count = len(list(data_dir2.glob('*/*.png')))
# print(image_count)

batch_size = 32
img_height = 192
img_width = 192

# train_ds = tf.keras.preprocessing.image_dataset_from_directory(
#     data_dir2,
#     validation_split=0.2,
#     subset="training",
#     seed=123,
#     image_size=(img_height, img_width),
#     batch_size=batch_size)

# # val_ds = tf.keras.preprocessing.image_dataset_from_directory(
# #     data_dir2,
# #     validation_split=0.2,
# #     subset="validation",
# #     seed=123,
# #     image_size=(img_height, img_width),
# #     batch_size=batch_size)


# class_names = train_ds.class_names

class_names = ['no_worms', 'worms']
# print(class_names)

# AUTOTUNE = tf.data.experimental.AUTOTUNE

# train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
# val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# normalization_layer = layers.experimental.preprocessing.Rescaling(1./255)

# normalized_ds = train_ds.map(lambda x, y: (normalization_layer(x), y))
# image_batch, labels_batch = next(iter(normalized_ds))
# first_image = image_batch[0]
# # Notice the pixels values are now in `[0,1]`.
# print(np.min(first_image), np.max(first_image)) 


# num_classes = len(class_names)

num_classes = 2

data_augmentation = keras.Sequential(
  [
    layers.experimental.preprocessing.RandomFlip("horizontal", 
                                                 input_shape=(img_height, 
                                                              img_width,
                                                              3)),
    layers.experimental.preprocessing.RandomRotation(0.1),
    layers.experimental.preprocessing.RandomZoom(0.1),
  ]
)


model = Sequential([
  data_augmentation,
  layers.experimental.preprocessing.Rescaling(1./255),
  layers.Conv2D(16, 3, padding='same', activation='relu'),
  layers.MaxPooling2D(),
  layers.Conv2D(32, 3, padding='same', activation='relu'),
  layers.MaxPooling2D(),
  layers.Conv2D(64, 3, padding='same', activation='relu'),
  layers.MaxPooling2D(),
  layers.Dropout(0.2),
  layers.Flatten(),
  layers.Dense(128, activation='tanh'),
  layers.Dense(num_classes)
])

model.compile(optimizer='adam',
              loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
              metrics=['accuracy'])

# checkpoint_path = "training_2/cp-{epoch:04d}.ckpt"
# checkpoint_dir = os.path.dirname(checkpoint_path)

# # Create a callback that saves the model's weights every 5 epochs
# cp_callback = tf.keras.callbacks.ModelCheckpoint(
#     filepath=checkpoint_path, 
#     verbose=1, 
#     save_weights_only=True,
#     period=5)

# es_Callback = tf.keras.callbacks.EarlyStopping(monitor='val_loss', mode='auto',patience=8)

# model.summary()

model.load_weights('saved_model/my_model2.h5')

# epochs = 100
# history = model.fit(
#   train_ds,
#   validation_data=val_ds,
#   epochs=epochs,
#   callbacks=[cp_callback,es_Callback]
# )
# model.save('saved_model/my_model.h5') 

# sunflower_url = "https://storage.googleapis.com/download.tensorflow.org/example_images/592px-Red_sunflower.jpg"
# sunflower_path = tf.keras.utils.get_file('Red_sunflower', origin=sunflower_url)

# img = keras.preprocessing.image.load_img(
#     '271.png', target_size=(img_height, img_width)
# )
# img_array = keras.preprocessing.image.img_to_array(img)
# img_array = tf.expand_dims(img_array, 0) # Create a batch
# predictions1 = model.predict(img_array)
# score = tf.nn.softmax(predictions1[0])
# print(
#     "271 - worm belongs to {} with a {:.2f} percent confidence."
#     .format(class_names[np.argmax(score)], 100 * np.max(score))
# )

execution_path = os.path.join(os.getcwd(),'temp_imgs')

all_files = natsorted(os.listdir(execution_path))
all_images_array = []
for each_file in all_files:
    if(each_file.endswith(".jpg") or each_file.endswith(".png")):
        all_images_array.append(os.path.join(execution_path,each_file))

predictions_array = []
for each_file in all_images_array:
    this_img = keras.preprocessing.image.load_img(each_file, target_size=(img_height, img_width))
    this_img_array = tf.expand_dims(keras.preprocessing.image.img_to_array(this_img), 0)
    this_prediction = model.predict(this_img_array)
    predictions_array.append(this_prediction)
    score = tf.nn.softmax(this_prediction[0])
    print(np.array(score[1]),',')
    # print(
    # each_file, "- {} with a {:.2f} percent confidence."
    # .format(class_names[np.argmax(score)], 100 * np.max(score))
    # )



# print('asdfasdf')
# model.save('saved_model/my_model.h5') 
# new_model = tf.keras.models.load_model('saved_model/my_model')
