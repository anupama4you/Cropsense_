import 'dart:async';
import 'dart:convert';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String prediction;

  const ChatPage({Key? key, required this.prediction}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final openai = OpenAI.instance.build(
    token: dotenv.env['OPEN_AI_KEY'],
    baseOption: HttpSetup(),
    enableLog: true,
  );
  final ChatUser _current =
      ChatUser(id: '1', firstName: 'User', lastName: 'name');
  final ChatUser gptchatuse =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'GPT');
  final List<ChatMessage> _messages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    // Send a predefined message when the chat page is loaded
    sendPredefinedMessage(widget.prediction);
  }

  Future<void> sendPredefinedMessage(String message) async {
    // Display the user's message in the chat
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
            user: _current,
            createdAt: DateTime.now(),
            text:
                'list out separately the details, symptoms, recommended treatments, and preventive measures of ${widget.prediction}',
          ));
    });

    // Create message history for GPT API request
    List<Messages> messageHistory = _messages
        .map((m) => m.user == _current
            ? Messages(role: Role.user, content: m.text)
            : Messages(role: Role.assistant, content: m.text))
        .toList();
    int maxTokens = 150;
    // Send a request to the GPT API
    final request = ChatCompleteText(
      model: Gpt4ChatModel(),
      messages: messageHistory,
      maxToken: maxTokens,
    );

    final response = await openai.onChatCompletion(request: request);

    for (var element in response!.choices) {
      if (element.message != null) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              user: gptchatuse,
              createdAt: DateTime.now(),
              text: element.message!.content,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackpressed,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(0, 166, 126, 1),
          title: const Text(
            'CropSense-Chat',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: DashChat(
          currentUser: _current,
          messageOptions: const MessageOptions(
            currentUserContainerColor: Colors.black,
            containerColor: Color.fromRGBO(0, 166, 126, 1),
            textColor: Colors.white,
          ),
          onSend: (ChatMessage m) {
            getChatResponse(m);
          },
          messages: _messages,
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
    });
    List<Messages> messageHistory = _messages
        .map((m) => m.user == _current
            ? Messages(role: Role.user, content: m.text)
            : Messages(role: Role.assistant, content: m.text))
        .toList();
    final request = ChatCompleteText(
        model: GptTurbo0301ChatModel(),
        messages: messageHistory,
        maxToken: 325);
    final response = await openai.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message != null) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
                user: gptchatuse,
                createdAt: DateTime.now(),
                text: element.message!.content),
          );
        });
      }
    }
  }

  Future<bool> _onBackpressed() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Chat?'),
        content: Text('Do you want to save this chat?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // Save chat logic goes here
              await saveChatToLocalStorage();
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );

    // If the user dismisses the dialog, return false
    // Otherwise, return the user's choice
    return result ?? false;
  }

  Future<void> saveChatToLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Convert the chat messages to a format suitable for storage (e.g., JSON)
    List<String> chatMessages = _messages
        .map((message) => message.toJson())
        .toList()
        .map((json) => jsonEncode(json))
        .toList();
    // Save the chat messages to local storage
    await prefs.setStringList('chatMessages', chatMessages);
  }
}
