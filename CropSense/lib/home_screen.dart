import 'dart:io';
import 'dart:ui';
import 'package:cropsense/photoDisplay.dart';
import 'package:cropsense/splash.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? selectedImage;
  String baseUrl = 'http://10.0.2.2:5000/predict';
  String prediction = '';
  double celTemp = 0;
  double fahTemp = 0;
  var tempPhoto = '';
  var condition = '';
  final fontColor = Colors.white;
  final picker = ImagePicker();
  bool _isMounted = false;

  String locationMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    init();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void init() async {
    if (_isMounted) {
      if (await _checkLocationPermission()) {
        var location = await getCurrentLocation();
        if (_isMounted) {
          setState(() {
            locationMessage = '${location.latitude},${location.longitude}';
          });
          setWeatherData();
        }
      } else {
        if (_isMounted) {
          setState(() {
            locationMessage = 'Location permission not granted';
          });
        }
      }
    }
  }

  Future<void> setWeatherData() async {
    var address = 'http://api.weatherapi.com/v1/current.json';
    var key = dotenv.env['WEATHER_KEY'];
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

        // Update locationMessage with weather information
      } else {
        // Handle error response
      }
    } catch (e) {
      // Handle network errors
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

  Future<void> capturePhotoFromCamera(BuildContext dialogContext) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      String prediction = await uploadImage(
          pickedFile.path, context); // Pass context to uploadImage
      if (prediction != 'null') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDisplay(
              imagePath: pickedFile.path,
              prediction: prediction,
            ),
          ),
        );
      } // Ensure async call completes
    }
  }

  Future<void> uploadPhotoFromGallery(BuildContext dialogContext) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.of(dialogContext).pop(); // Dismiss the dialog
      String prediction = await uploadImage(
          pickedFile.path, context); // Pass context to uploadImage
      if (prediction != 'null') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDisplay(
              imagePath: pickedFile.path,
              prediction: prediction,
            ),
          ),
        );
      } // Ensure async call completes
    }
  }

  Future<String> uploadImage(String filePath, BuildContext context) async {
    var uri = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        String prediction =
            response.body.replaceAll('_', ' ').replaceAll('"', '');

        return prediction; // Return prediction value
      } else {
        print('Failed to upload image');
        return 'null'; // Return null if prediction failed
      }
    } catch (e) {
      print('Error uploading image: $e');
      return 'null'; // Return null if prediction failed
    }
  }

  Future<List<Map<String, String>>> _loadPlantData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? plantDataJson = prefs.getString('PlantData');
    if (plantDataJson != null) {
      List<dynamic> plantDataList = jsonDecode(plantDataJson);
      return plantDataList
          .map((data) => Map<String, String>.from(data))
          .toList();
    }
    return [];
  }

  Future<List<Widget>> getMyPlants() async {
    List<Widget> weatherCards = [];
    List<Map<String, String>> plantData = await _loadPlantData();

    for (var data in plantData) {
      String imagePath = data['imagePath']!;
      String prediction = data['prediction']!;

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
                  child: Image.file(
                    File(imagePath),
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(
                      8.0), // Added padding for better text visibility
                  child: Text(
                    prediction,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: "Readex Pro",
                      letterSpacing: 0,
                    ),
                    maxLines: 2, // Limiting to 2 lines
                    overflow: TextOverflow
                        .ellipsis, // Making sure text wraps instead of being clipped
                  ),
                ),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/AppBar-logo.svg', height: 24),
            const SizedBox(
              width: 8.0,
            ),
            const Text(
              "CropSense",
              style: TextStyle(color: Colors.black),
            )
          ],
        ),
        backgroundColor: Colors.white,
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
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context)
                                      .size
                                      .height, // Ensure it takes at least the height of the screen
                                ),
                                child: IntrinsicHeight(
                                  child: Splash(),
                                ),
                              ),
                            ); // Display a loading indicator while waiting for the API call to complete
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
                              height: 300,
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
                            height: 300,
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
                                FutureBuilder<List<Widget>>(
                                  future: getMyPlants(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<List<Widget>> snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'));
                                    } else if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const Center(
                                          child: Text('No plants found.'));
                                    } else {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: snapshot.data!,
                                        ),
                                      );
                                    }
                                  },
                                ),
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
                                          height: 20,
                                        )),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Upload Image',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                content:
                                                    const SingleChildScrollView(
                                                  child: ListBody(
                                                    children: <Widget>[
                                                      Text(
                                                        'Provide a photo of the plant',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Text(
                                                        'You can choose any Options for uploading ',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      capturePhotoFromCamera(
                                                          dialogContext);
                                                    },
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.camera_outlined,
                                                          color: Colors
                                                              .lightGreenAccent,
                                                        ),
                                                        VerticalDivider(),
                                                        Text(
                                                          'Camera',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .lightGreenAccent),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      uploadPhotoFromGallery(
                                                          dialogContext);
                                                    },
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
                                                          color: Colors
                                                              .lightGreenAccent,
                                                        ),
                                                        VerticalDivider(),
                                                        Text(
                                                          'Gallery',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .lightGreenAccent),
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                ],
                                                backgroundColor: Colors.black,
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1.0,
                                                color: Colors.white30,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
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
                                              ),
                                            ],
                                          ),
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
    );
  }
}
