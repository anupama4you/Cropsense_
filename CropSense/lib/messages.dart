import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

import 'package:cropsense/chatDetails.dart'; // Import the new ChatDetailPage

class Messages extends StatefulWidget {
  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  List<Map<String, dynamic>> _allChatThreads = [];

  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'User', lastName: 'name');
  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'GPT');

  @override
  void initState() {
    super.initState();
    //getChatsFromLocalStorage();
    _loadChatThreads();
  }

  Future<void> _loadChatThreads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? allMessagesJson = prefs.getString('AllMessages');
    if (allMessagesJson != null) {
      List<dynamic> allMessagesMapList = jsonDecode(allMessagesJson);
      setState(() {
        _allChatThreads = allMessagesMapList.map((chatThread) {
          String heading = chatThread['heading'] as String;
          List<ChatMessage> messages = (chatThread['messages'] as List<dynamic>)
              .map((messageMap) =>
                  ChatMessage.fromJson(messageMap as Map<String, dynamic>))
              .toList();
          return {
            'heading': heading,
            'messages': messages,
          };
        }).toList();
      });
    }
    //prefs.remove('AllMessages');
  }

  void getChatsFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the JSON string containing all chat threads
    String? chatJson = prefs.getString('AllMessages');

    // Parse the JSON string into a list of dynamic objects
    List<dynamic> allMessages = chatJson != null ? jsonDecode(chatJson) : [];
    List<String> headings =
        allMessages.map((chat) => chat['heading'] as String).toList();
    print(allMessages);
    print(headings);
  }

  void _openChatDetailPage(List<ChatMessage> chatThread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chatThread: chatThread,
          currentUser: _currentUser,
          gptChatUser: _gptChatUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat History',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _allChatThreads.length,
        itemBuilder: (context, threadIndex) {
          Map<String, dynamic> chatThreadMap = _allChatThreads[threadIndex];
          String heading = chatThreadMap['heading'];
          List<ChatMessage> chatThread = chatThreadMap['messages'];
          String lastMessagePreview =
              chatThread.isNotEmpty ? chatThread.first.text : '';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: Colors.black,
            child: InkWell(
              onTap: () => _openChatDetailPage(chatThread),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListTile(
                      title: Text(
                        heading,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        lastMessagePreview.length > 30
                            ? '${lastMessagePreview.substring(0, 30)}...'
                            : lastMessagePreview,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ),
                  ]),
            ),
          );
        },
      ),
      backgroundColor: Colors.black87,
    );
  }
}
