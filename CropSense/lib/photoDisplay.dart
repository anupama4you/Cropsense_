import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:cropsense/chat_screen_2.dart';

class PlantDisplay extends StatelessWidget {
  final String imagePath;
  final String prediction;

  PlantDisplay({required this.imagePath, required this.prediction}) {
    Future.microtask(() => _saveToLocalStorage(imagePath, prediction));
  }

  Future<void> _saveToLocalStorage(String imagePath, String prediction) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load existing data from local storage
    String? plantDataJson = prefs.getString('PlantData');
    List<dynamic> plantDataList =
        plantDataJson != null ? jsonDecode(plantDataJson) : [];

    // Create a new entry
    Map<String, String> newEntry = {
      'imagePath': imagePath,
      'prediction': prediction,
    };

    // Add the new entry to the list
    plantDataList.add(newEntry);

    // Save the updated list back to local storage
    await prefs.setString('PlantData', jsonEncode(plantDataList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plant Display',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          Center(
            child: Image.file(File(imagePath)),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(prediction: prediction),
                ),
              );
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(
                const BorderSide(color: Colors.green),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              padding: MaterialStateProperty.all(
                EdgeInsets.fromLTRB(10, 10, 10, 0),
              ),
            ),
            child: Text(
              prediction,
              style: TextStyle(fontFamily: "Readex Pro", color: Colors.black),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
