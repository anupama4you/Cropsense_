import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _plantController = TextEditingController();
  TextEditingController _remedyController = TextEditingController();
  bool loadingPrediction = false;
  bool loadingChatGpt = false;
  bool open = false;
  List<String> results = [];
  XFile? selectedImage;
  String baseUrl = 'http://10.0.2.2:5000/predict';
  String chatGptBackendAPI = 'http://10.0.2.2:3000/';
  String chatGptResponse = '';

  final picker = ImagePicker();
  File? _image;

  // Method to capture a photo from the camera
  Future<void> capturePhotoFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        selectedImage = pickedFile;
      });
      uploadImage(pickedFile.path);
    }
  }

  // Method to upload a photo
  Future<void> uploadPhotoFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      print('Server Response: ${response.body}');
      print('Image uploaded successfully');
    } else {
      print('Failed to upload image');
    }
  }


  Future<void> pickAndUploadImage() async {

    File imageFile = File(selectedImage!.path);

    try {
      var request = http.MultipartRequest(
        'POST', Uri.parse(baseUrl),

      );
      Map<String,String> headers={
        "Content-type": "multipart/form-data"
      };
      request.files.add(
        http.MultipartFile(
          'file',
          imageFile.readAsBytes().asStream(),
          imageFile.lengthSync(),
          filename: 'PotatoEarlyBlight2.JPG',
          contentType: MediaType('image','jpeg'),
        ),
      );
      request.headers.addAll(headers);
      // request.fields.addAll({
      //   "name":"test",
      //   "email":"test@gmail.com",
      //   "id":"12345"
      // });
      print("request: "+request.toString());
      var res = await request.send();
      print("This is response:"+res.toString());
    } catch (e) {
      // Handle network or request error
      print('Error: $e');
    }
  }

  Future<void> predictDisease() async {

    Uint8List imageBytes = await selectedImage!.readAsBytes();
    String imageBase64 = base64Encode(imageBytes);

    // Create the request body as a JSON object
    final Map<String, dynamic> requestBody = {
      'image': imageBase64,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json', // Set the content type
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      results.add(responseData['Disease']);
      _plantController.text = responseData['Plant'];
      _remedyController.text = responseData['remedy'];
      print(responseData.toString());
    } else {
      // Handle error response
      throw Exception('Failed to predict disease');
    }
  }

  Future<void> sendChatGPT() async {
    final url = Uri.parse(chatGptBackendAPI);
    setState(() {
      loadingChatGpt = true;
    });
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'prompt': 'list out separately the details, symptoms, recommended treatments, and preventive measures of ${results[0]}'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        setState(() {
          loadingChatGpt = false;
          chatGptResponse = responseBody['response'];
        });
        print(responseBody);
      } else {
        // Handle error response
        setState(() {
          loadingChatGpt = false;
        });
        throw Exception('Failed to make the POST request');
      }
    } catch (e) {
      // Handle network or request error
      print(e);
      setState(() {
        loadingChatGpt = false;
      });
      throw Exception('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CropSense'),

        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Show Snackbar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This is a snackbar')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: 'Go to the next page',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Next page'),
                    ),
                    body: const Center(
                      child: Text(
                        'This is the next page',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ));
            },
          ),
        ],
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

              // Display the selected image if available
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(File(selectedImage!.path), width: 200, height: 200),
                ),

              if (loadingPrediction)
                CircularProgressIndicator() // Loading indicator
              else if (results.isNotEmpty)
                Column(children: [
                  Text(
                    'With high confidence the disease is: ${results[0].replaceAll("_", " ")}',
                    style: TextStyle(fontSize: 14), // Adjust the font size (e.g., 18)
                  ),
                  Text('Plant: ${_plantController.text}', style: TextStyle(fontSize: 14),), // Adjust the font size
                  Text('Remedy: ${_remedyController.text}', style: TextStyle(fontSize: 10),), // Adjust the font size
                ],
                ),
              SizedBox(height: 10,),
              if(loadingChatGpt)
                CircularProgressIndicator()
              else if(chatGptResponse != '')
                Text('${chatGptResponse}', style: TextStyle(fontSize: 10),),

              ElevatedButton(
                onPressed: () async {
                  // Save data
                },
                child: Text('Save'),
              ),
              if (open)
              // Success message
                AlertDialog(
                  title: Text('Information saved successfully!'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          open = false;
                        });
                      },
                      child: Text('Close'),
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
