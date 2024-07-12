import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.optimizers import RMSprop
from tensorflow.keras.applications import VGG16
from tensorflow.keras import layers, models
import math
import matplotlib.pyplot as plt
from sklearn.metrics import classification_report, confusion_matrix
import numpy as np

batch_size = 32

# Images Rescaled  
train_datagen = ImageDataGenerator(
    rescale=1 / 255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode='nearest',
    validation_split=0.2   
)

# train_datagen generator
train_generator = train_datagen.flow_from_directory(
    'Student_images/', 
    target_size=(200, 200),  
    batch_size=batch_size,
    # classes 
    classes=['001', '002'],
    class_mode='categorical',
    subset='training' 
)

validation_generator = train_datagen.flow_from_directory(
    'Student_images/',  
    target_size=(200, 200),
    batch_size=batch_size,
    # classes 
    classes=['001', '002'],
    class_mode='categorical',
    subset='validation' 
)

base_model = VGG16(weights='imagenet', include_top=False, input_shape=(200, 200, 3))

# layers 
for layer in base_model.layers:
    layer.trainable = False

model = models.Sequential([
    base_model,
    layers.Flatten(),
    layers.Dense(512, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(128, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(2, activation='softmax')
])

model.summary()

model.compile(loss='categorical_crossentropy',
              optimizer=RMSprop(learning_rate=0.0001),
              metrics=['acc'])

total_sample = train_generator.n
total_val_sample = validation_generator.n
print(total_sample)
print(total_val_sample)
n_epochs = 10

history = model.fit(
    train_generator,
    steps_per_epoch=math.ceil(total_sample / batch_size),
    epochs=n_epochs,
    validation_data=validation_generator,
    validation_steps=math.ceil(total_val_sample / batch_size),
    verbose=1
)

model.save('Face_model.h5')

print("------------------ Face Model Saved ------------------")

#   accuracy and loss
def plot_history(history):
    acc = history.history['acc']
    val_acc = history.history['val_acc']
    loss = history.history['loss']
    val_loss = history.history['val_loss']
    epochs = range(len(acc))

    plt.plot(epochs, acc, 'r', label='Training accuracy')
    plt.plot(epochs, val_acc, 'b', label='Validation accuracy')
    plt.title('Training and validation accuracy')
    plt.legend()

    plt.figure()
    plt.plot(epochs, loss, 'r', label='Training loss')
    plt.plot(epochs, val_loss, 'b', label='Validation loss')
    plt.title('Training and validation loss')
    plt.legend()

    plt.show()

plot_history(history)

 