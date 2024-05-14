import 'dart:io';
import 'package:cropsense/chat_screen_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text('Home Screen')),
    Center(child: Text('Search Screen')),
    Center(child: Text('Profile Screen')),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Handle location permission denied scenario
      print('Location permission denied');
    } else {
      print('Location permission granted');
    }
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

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

  Future<void> checkStoredChatMessages() async {
    // Get an instance of SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the list of JSON strings from local storage
    List<String>? chatMessagesJson = prefs.getStringList('chatMessages');

    if (chatMessagesJson == null) {
      print('No chat messages found in storage.');
    } else {
      print('Stored chat messages:');
      // Print each stored chat message JSON string
      for (String jsonStr in chatMessagesJson) {
        print(jsonStr);
      }
    }
  }

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
        title: const Text(
          'CropSense',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF96DD80),
                    Color(0xFF539F00),
                    Color(0xFF96DB80),
                  ],
                  stops: [0, 0.5, 0.75],
                  begin: AlignmentDirectional(1, -1),
                  end: AlignmentDirectional(-1, 1),
                ),
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Welcome',
                        style: TextStyle(fontSize: 32),
                      )),
                  Card(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Weather Information',
                            style: TextStyle(
                              fontSize: 24,
                            ),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.all(5),
                            child: (Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    'https://picsum.photos/seed/194/600',
                                    width: 133,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      '30 C',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    Text(
                                      '17 C',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                )
                              ],
                            )))
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_max_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
