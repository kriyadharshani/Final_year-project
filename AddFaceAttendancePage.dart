import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class AddFaceAttendancePage extends StatefulWidget {
  @override
  _AddFaceAttendancePageState createState() => _AddFaceAttendancePageState();
}

class _AddFaceAttendancePageState extends State<AddFaceAttendancePage> {
  String _errorText = "";
  String _photoPath = ""; // Variable to store the photo path
  String _predictedClass = "";
  bool _predictionCompleted = false;
  String _currentLocation = "Fetching location...";
  bool _isWithinRange = false;
  bool _isLoading = false; // Flag to control loading state

  // Target location coordinates and range in meters
  final double targetLatitude =  51.3963726; // Example latitude
  final double targetLongitude = -0.1143577; // Example longitude
  final double allowedRange = 1000; // Example range in meters

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<String> _uploadPhoto(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().getImage(source: source);

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('Face_Attendance_photos/${DateTime.now().millisecondsSinceEpoch}${file.path}');

        await storageRef.putFile(file);

        // Obtain the download URL
        String downloadURL = await storageRef.getDownloadURL();

        // Save the download URL to _photoPath
        setState(() {
          _photoPath = downloadURL;
        });

        return downloadURL;
      }

      return '';
    } catch (e) {
      print('Error picking and uploading photo: $e');
      return '';
    }
  }

  Future<void> _makePredictionRequest(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        print('Image URL is empty');
        return;
      }

      setState(() {
        _isLoading = true; // Show loading indicator when making prediction request
      });

      final response = await http.post(
        Uri.parse('http:// 192.168.140.1:5000/predict'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        // Parse the response JSON
        final Map<String, dynamic> data = json.decode(response.body);

        // Get the predicted class
        final String predictedClass = data['prediction'];

        // Update the state with the predicted class
        setState(() {
          _predictedClass = predictedClass;
          _predictionCompleted = true;
          _isLoading = false; // Hide loading indicator when prediction is completed
        });

        print('Predicted Student: $_predictedClass');

        // Fetch the current location once the prediction is completed
        _getCurrentLocation();
      } else {
        setState(() {
          _isLoading = false; // Hide loading indicator if prediction request fails
        });
        print('Prediction request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator if prediction request throws an error
      });
      print('Error making prediction request: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentLocation = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentLocation = 'Location permissions are denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentLocation = 'Location permissions are permanently denied.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = "${position.latitude}, ${position.longitude}";
        _isWithinRange = _checkIfWithinRange(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _currentLocation = 'Error getting location: $e';
      });
    }
  }

  bool _checkIfWithinRange(double currentLatitude, double currentLongitude) {
    double distance = Geolocator.distanceBetween(
      targetLatitude,
      targetLongitude,
      currentLatitude,
      currentLongitude,
    );
    return distance <= allowedRange;
  }

  Future<void> _addFaceAttendance() async {
    try {
      setState(() {
        _errorText = "";
      });

      // Ensure prediction is completed before adding data to Firestore
      if (!_predictionCompleted) {
        setState(() {
          _errorText = 'Please wait for the prediction to complete.';
        });
        return;
      }

      // Get the current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DateTime currentDateTime = DateTime.now();
      // Create a Face_Attendance data map with the predicted class as 'Face_AttendanceName'
      Map<String, dynamic> faceAttendanceData = {
        'user_id': userId,
        'Face_AttendanceName': _predictedClass,
        'photo_path': _photoPath,
        'date_time': currentDateTime,
        'location': _currentLocation,
      };

      // Store Face_Attendance data in Firestore
      await FirebaseFirestore.instance.collection('Face_Attendances').add(faceAttendanceData);

      // Face_Attendance added successfully
      setState(() {
        _errorText = 'Attendance  Marked successfully   !';
      });
    } catch (e) {
      setState(() {
        _errorText = 'Error adding Student: $e';
      });
    }
  }

  Widget _buildImageWidget() {
    if (_photoPath.isNotEmpty) {
      return Image.network(
        _photoPath,
        height: 150,
        width: 150,
        fit: BoxFit.cover,
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Mark Attendance',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue, // Set app bar background color to blue
      ),
      backgroundColor: Colors.blue, // Set scaffold background color to blue

    body: Stack( // Stack widget to overlay loading pop-up on top of content
    children: [
    SingleChildScrollView(
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(

      children: [

        SizedBox(height: 40),
        Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are in: $_currentLocation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _isWithinRange ? 'You are within the allowed range.' : 'You are not within the allowed range.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isWithinRange ? Colors.green : Colors.red,
                  ),
                ),


                SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    if (!_isWithinRange) return; // Disable camera if user is out of range
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('Confirm'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _uploadPhoto(ImageSource.camera);
                                  await _makePredictionRequest(_photoPath);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },

                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isWithinRange ? Colors.blue : Colors.grey, // Change color based on within range or not
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white), // Camera icon
                        SizedBox(width: 5),
                        Text(
                          'Open Camera',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),


                ),

              ],
            ),
          ),
        ),






        SizedBox(height: 16),
        if (_predictionCompleted)
          Column(
            children: [
              Text(
                'Predicted Student: $_predictedClass',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Container(
                        height: 200, // Adjust the height as needed
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: _photoPath.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(_photoPath),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addFaceAttendance,
                child: Text('Confirm my Attendance'),
              ),
            ],
          ),
        SizedBox(height: 8),
        Text(
          _errorText,
          style: TextStyle(color: Colors.red),
        ),
      ],
    ),
    ),
    ),
      if (_isLoading) // Show loading pop-up if isLoading is true
        Container(
          color: Colors.black.withOpacity(0.5), // Semi-transparent black background
          child: Center(
            child: CircularProgressIndicator(), // Loading indicator
          ),
        ),
    ],
    ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AddFaceAttendancePage(),
    );
  }
}

