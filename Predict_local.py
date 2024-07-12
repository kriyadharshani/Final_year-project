import warnings
warnings.filterwarnings('ignore', category=FutureWarning)
import tensorflow as tf
classifierLoad = tf.keras.models.load_model('Face_model.h5')
import numpy as np
import pandas as pd
from keras.preprocessing import image

test_image = image.load_img('22.jpg', target_size=(200, 200))
test_image = np.expand_dims(test_image, axis=0)
result = classifierLoad.predict(test_image)
print(result)
print("------------------ Student Face Matched ------------------")
if result[0][0] == 1:
    print("001")

elif result[0][1] == 1:
    print("002")
elif result[0][2] == 1:
    print("003")


 