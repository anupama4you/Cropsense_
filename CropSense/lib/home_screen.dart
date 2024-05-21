import 'dart:io';
import 'package:cropsense/chat_screen_2.dart';
import 'package:cropsense/photoDisplay.dart';
import 'package:cropsense/messages.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? selectedImage;
  String baseUrl = 'http://10.0.2.2:5000/predict';
  String prediction = '';
  var celTemp;
  var fahTemp;
  var tempPhoto;
  var condition;
  final fontColor = Colors.white;
  final picker = ImagePicker();
  File? _image;
  int _selectedIndex = 0;
  String locationMessage = 'Loading...';
  final int homePageIndex = 0;
  final int messagesPageIndex = 1;
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (await _checkLocationPermission()) {
      var location = await getCurrentLocation();
      //var address = await _getStateFromLatLng(location);
      setState(() {
        locationMessage = '${location.latitude},${location.longitude}';
      });
      setWeatherData();
    } else {
      setState(() {
        locationMessage = 'Location permission not granted';
      });
    }
  }

  Future<void> setWeatherData() async {
    var address = 'http://api.weatherapi.com/v1/current.json';
    var key = "8d8f0b55cca2497ebe351305240605";
    var apiUrl = '$address?key=$key&q=$locationMessage';
    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parse the JSON response
        var weatherData = jsonDecode(response.body);

        // Extract the weather information
        celTemp = weatherData['current']['temp_c'];
        fahTemp = weatherData['current']['temp_f'];
        tempPhoto = 'https:${weatherData['current']['condition']['icon']}';
        condition = weatherData['current']['condition']['text'];
        print("${celTemp}, ${fahTemp}, ${tempPhoto},${condition}");
        // Update locationMessage with weather information
      } else {
        // Handle error response
        print('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors
      print('Error fetching weather data: $e');
    }
  }

  Future<bool> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

// Inside _HomeScreenState class

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == messagesPageIndex) {
      // Navigate to MessagesPage
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MessageDisplay()), // Replace MessagesPage with your actual MessagesPage widget
      );
    } else {
      // Navigate to HomePage or perform any other action based on index
      // You can handle the HomePage navigation here or perform other actions as needed
    }
  }

  Future<void> capturePhotoFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        selectedImage = pickedFile;
      });
      // predictDisease(pickedFile.path);
      uploadImage(pickedFile.path);

      // Navigate to plantDisplay page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantDisplay(
            imagePath: pickedFile.path,
          ),
        ),
      );
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

  List<Widget> getMyPlants() {
    List<Widget> weatherCards = [];

    for (var i = 0; i < 10; i++) {
      weatherCards.add(
        Padding(
          padding: const EdgeInsets.all(5),
          child: Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://picsum.photos/seed/711/600',
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                ),
                const Text(
                  'Hello World',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: "Readex Pro",
                      letterSpacing: 0),
                )
              ],
            ),
          ),
        ),
      );
    }

    return weatherCards;
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
              color: Colors.black87,
            ),
            Align(
              alignment: const AlignmentDirectional(0, 0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Welcome',
                          style: TextStyle(fontSize: 32, color: fontColor),
                        )),
                    FutureBuilder(
                        future: setWeatherData(),
                        builder: (BuildContext context,
                            AsyncSnapshot<void> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(); // Display a loading indicator while waiting for the API call to complete
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 0, 20),
                              child: Stack(
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.95,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [
                                              Color(0XFF673AB7),
                                              Colors.blue
                                            ],
                                            stops: [
                                              0,
                                              0.7
                                            ],
                                            begin: AlignmentDirectional(-1, -1),
                                            end: AlignmentDirectional(1, 1)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 0.95,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: Text(
                                                    'Weather Information',
                                                    style: TextStyle(
                                                        fontFamily:
                                                            "Readex Pro",
                                                        color: fontColor,
                                                        fontSize: 24,
                                                        letterSpacing: 0),
                                                  )),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Column(children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      tempPhoto,
                                                      width: 133,
                                                      height: 110,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Text(
                                                    condition,
                                                    style: TextStyle(
                                                      color: fontColor,
                                                      fontFamily: "Readex Pro",
                                                    ),
                                                  )
                                                ]),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Text(
                                                      '${celTemp} C',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          fontSize: 24,
                                                          letterSpacing: 0,
                                                          color: fontColor),
                                                    ),
                                                    Text(
                                                      '${fahTemp} F',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              "Readex Pro",
                                                          letterSpacing: 0,
                                                          color: fontColor),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          )
                                        ]),
                                  )
                                ],
                              ),
                            );
                          }
                        }),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 20),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: 0.4,
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.95,
                              height: 230,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF673AB7), Colors.blue],
                                  stops: [0, 0.7],
                                  begin: AlignmentDirectional(1, 0),
                                  end: AlignmentDirectional(-1, 0),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.95,
                            height: 230,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Your Plants',
                                    style: TextStyle(
                                        fontFamily: "Readex Pro",
                                        fontSize: 24,
                                        color: fontColor,
                                        letterSpacing: 0),
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: getMyPlants()),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 20),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: 0.4,
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.95,
                              height: 250,
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFF673AB7), Colors.blue],
                                      stops: [0, 0.9],
                                      begin: AlignmentDirectional(1, 0),
                                      end: AlignmentDirectional(-1, 0)),
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.95,
                            height: 300,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('Features',
                                        style: TextStyle(
                                            fontFamily: "Readex Pro",
                                            fontSize: 24,
                                            color: fontColor,
                                            letterSpacing: 0)),
                                    const Opacity(
                                      opacity: 0,
                                      child: Divider(
                                        thickness: 2,
                                      ),
                                    ),
                                    Text(
                                      "Imagine having a personalized Crop Expert right in your pocket !",
                                      style: TextStyle(
                                        fontFamily: "Readex Pro",
                                        letterSpacing: 0,
                                        color: fontColor,
                                      ),
                                    ),
                                    const Opacity(
                                      opacity: 0,
                                      child: Divider(
                                        thickness: 2,
                                      ),
                                    ),
                                    RichText(
                                        textScaleFactor: MediaQuery.of(context)
                                            .textScaleFactor,
                                        text: const TextSpan(children: [
                                          TextSpan(
                                              text: "Photo",
                                              style: TextStyle(
                                                  fontFamily: "Readex Pro",
                                                  color: Color(0xFF0fa968),
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text:
                                                  " - is all you need for your expert to analyse the plant",
                                              style: TextStyle(
                                                  fontFamily: "Readex Pro",
                                                  letterSpacing: 0))
                                        ])),
                                    const Opacity(
                                      opacity: 0,
                                      child: Divider(
                                        thickness: 2,
                                      ),
                                    ),
                                    RichText(
                                      textScaleFactor: MediaQuery.of(context)
                                          .textScaleFactor,
                                      text: const TextSpan(children: [
                                        TextSpan(
                                          text:
                                              'Have a personalized plant doctor specific for every plant diesase out there - Powered by ',
                                          style: TextStyle(
                                              fontFamily: "Readex Pro",
                                              letterSpacing: 0),
                                        ),
                                        TextSpan(
                                            text: 'ChatGPT',
                                            style: TextStyle(
                                              fontFamily: "Readex Pro",
                                              letterSpacing: 0,
                                              color: Color(0xFF108554),
                                            ))
                                      ]),
                                    ),
                                    const Opacity(
                                        opacity: 0,
                                        child: SizedBox(
                                          height: 43,
                                        )),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'AlertDialog Title'),
                                                content:
                                                    const SingleChildScrollView(
                                                  child: ListBody(
                                                    children: <Widget>[
                                                      Text(
                                                          'This is a demo alert dialog.'),
                                                      Text(
                                                          'Would you like to approve of this message?'),
                                                    ],
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed:
                                                        capturePhotoFromCamera,
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons
                                                            .camera_outlined),
                                                        Text('Camera'),
                                                      ],
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        uploadPhotoFromGallery,
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.upload_rounded,
                                                          size: 20,
                                                        ),
                                                        Text('Gallery')
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.upload_outlined,
                                              color: fontColor,
                                            ),
                                            const Opacity(
                                              opacity: 0,
                                              child: SizedBox(
                                                height: 20,
                                                child: VerticalDivider(
                                                    thickness: 0),
                                              ),
                                            ),
                                            Text(
                                              "Photo",
                                              style: TextStyle(
                                                  fontFamily: "Readex Pro",
                                                  letterSpacing: 0,
                                                  color: fontColor),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ]),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
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
