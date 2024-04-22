import 'dart:io';
import 'package:cropsense/chat_screen_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cropsense/camera_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? selectedImage;
  String baseUrl = 'http://10.0.2.2:5000/predict';
  String prediction = '';

  final picker = ImagePicker();
  File? _image;

  // Method to capture a photo from the camera
  Future<void> capturePhotoFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        selectedImage = pickedFile;
      });
      // predictDisease(pickedFile.path);
      uploadImage(pickedFile.path);
    }
  }

  // Method to upload a photo
  Future<void> uploadPhotoFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        selectedImage = pickedFile;
      });
      uploadImage(pickedFile.path);
    }
  }

  Future uploadImage(String filePath) async {
    var uri = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          prediction = response.body.replaceAll('_', ' ');
        });
        print(prediction);
        return response.body.replaceAll('_', ' ');
      } else {
        print('Failed to upload image');
        return 'Failed to upload image';
      }
    } catch (e) {
      print('Error uploading image: $e');
      return 'Error uploading image';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CropSense'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  await capturePhotoFromCamera(); // Call the method for capturing a photo from the camera
                },
                child: Text('Capture Photo'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await uploadPhotoFromGallery(); // Call the method for capturing a photo from the camera
                },
                child: Text('Upload from Gallery'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraView(),
                    ),
                  );
                },
                icon: const Icon(Icons.scanner_rounded, size: 50),
                label: const Text(
                  'Scan',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
              ),

              // Display the selected image if available
              if (selectedImage != null)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.file(File(selectedImage!.path),
                          width: 200, height: 200),
                    ),
                    // Display the prediction underneath the image
                    if (prediction.isNotEmpty)
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to ChatScreen when pressed
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatPage(
                                      prediction: prediction,
                                    )),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Prediction: $prediction',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
