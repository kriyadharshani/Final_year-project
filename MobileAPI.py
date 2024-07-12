import warnings
warnings.filterwarnings('ignore', category=FutureWarning)
from flask import Flask, request, jsonify
from keras.preprocessing import image
import numpy as np
import tensorflow as tf
import requests
from PIL import Image
from io import BytesIO
import cv2

app = Flask(__name__)

# Load   model
classifierLoad = tf.keras.models.load_model('Face_model.h5')

# Define dimensions
img_height = 200
img_width = 200

#  Haar Cascade Classifier for face detection
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

# Function to detect faces
def detect_faces(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.1, 4)
    return faces

@app.route('/predict', methods=['POST'])
def predict():
    # image URL from the request
    input_data = request.get_json()
    image_url = input_data['image_url']
    response = requests.get(image_url)
    img = Image.open(BytesIO(response.content))
    img = img.resize((img_height, img_width))
    opencv_image = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)

    # Detect faces
    faces = detect_faces(opencv_image)

    if len(faces) == 0:
        return jsonify({'prediction': 'No human face detected'})


    
    # Preprocess the input image
    test_image = image.img_to_array(img)
    test_image = np.expand_dims(test_image, axis=0)

    # Make predictions
    result = classifierLoad.predict(test_image)
    if result[0][0] == 1:
        prediction = "001"
    elif result[0][1] == 1:
        prediction = "002"
    elif result[0][2] == 1:
        prediction = "003"
    else:
        prediction = "Unknown"

    return jsonify({'prediction': prediction})

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
