import 'dart:convert';
import 'dart:io';
import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:chat_bubbles/bubbles/bubble_normal_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  List<Message> msgs = [];
  bool isTyping = false;

  bool loadingPrediction = false;
  bool loadingChatGpt = false;
  bool open = false;
  List<String> results = [];
  XFile? selectedImage;
  String baseUrl = 'http://10.0.2.2:5000/predict';
  String chatGptBackendAPI = 'http://10.0.2.2:3000/';
  String chatGptResponse = '';
  File? _image;

  // Function to send a text message
  void sendTextMsg() async {
    try {
      String text = controller.text;
      if (text.isNotEmpty) {
        setState(() {
          msgs.insert(0, Message(true, text: text));
          isTyping = true;
        });

        final url = Uri.parse(chatGptBackendAPI);
        final response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'prompt': text}),
        );

        if (response.statusCode == 200) {
          var json = jsonDecode(response.body);
          setState(() {
            isTyping = false;
            msgs.insert(0, Message(false, text: json["response"].toString().trimLeft()));
          });
        } else {
          print('Failed to send text message. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Failed to send text message. Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Some error occurred, please try again!")));
    }
  }

  // Function to send an image message
  void sendImageMsg(String imagePath) async {
    try {
      setState(() {
        msgs.insert(0, Message(true, imagePath: imagePath));
        isTyping = true;
      });

      // Here you can add your logic to process the image and get a response
      // For example, you might want to upload the image to a server, run it through a model, etc.
      String disease = await predictDisease(imagePath);
      // Simulate a response for now
      // await Future.delayed(Duration(seconds: 2));
      setState(() {
        isTyping = false;
        msgs.insert(0, Message(false, text: 'predicted leaf disease is: ${disease}'));
      });

      controller.text = 'list out separately the details, symptoms, recommended treatments, and preventive measures of ${disease}';
      sendTextMsg();

    } catch (e) {
      print('Failed to send image message. Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Some error occurred, please try again!")));
    }
  }

  // Method to capture a photo from the camera
  Future<void> capturePhotoFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        selectedImage = pickedFile;
      });
      predictDisease(pickedFile.path);
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
      // predictDisease(pickedFile.path);
      sendImageMsg(pickedFile.path);
    }
  }

  Future<String> predictDisease(String filePath) async {
    var uri = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print(response.body.replaceAll('_', ' '));
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


  // Main function to handle sending messages
  // void sendMsg({String? text, String? imagePath}) {
  //   if (text != null) {
  //     sendTextMsg(text);
  //   } else if (imagePath != null) {
  //     sendImageMsg(imagePath);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CropSense"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Image buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.camera_alt),
                label: Text('Capture'),
                onPressed: capturePhotoFromCamera,
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.photo),
                label: Text('Gallery'),
                onPressed: uploadPhotoFromGallery,
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: ListView.builder(
                controller: scrollController,
                itemCount: msgs.length,
                shrinkWrap: true,
                reverse: true,
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: isTyping && index == 0
                          ? Column(
                        children: [
                          BubbleNormal(
                            text: msgs[0].text ?? 'Uploading image',
                            isSender: true,
                            color: Colors.blue.shade100,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 16, top: 4),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text("Typing...")),
                          )
                        ],
                      )
                          : msgs[index].imagePath != null
                          ?  BubbleNormalImage(
                                id: 'id001',
                                image: Image.file(File(msgs[index].imagePath!)),
                                color: Colors.blue.shade100,
                                tail: true,
                                delivered: true,
                              )
                          : BubbleNormal(
                        text: msgs[index].text ?? 'Text is unavailable',
                        isSender: msgs[index].isSender,
                        color: msgs[index].isSender
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                      ),

                  );
                }),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (value) {
                          sendTextMsg();
                        },
                        textInputAction: TextInputAction.send,
                        showCursor: true,
                        decoration: const InputDecoration(
                            border: InputBorder.none, hintText: "Enter text"),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  sendTextMsg();
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              )
            ],
          ),
        ],
      ),
    );
  }
}
