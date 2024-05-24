import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    // Send a request to the GPT API
    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: messageHistory,
      maxToken: 325,
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
          backgroundColor: Colors.black,
          title: const Text(
            'CropSense-Chat',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
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
          inputOptions: const InputOptions(sendOnEnter: true),
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
    });
    List<Messages> messageHistory = _messages.reversed
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
              Navigator.of(context).pop(true);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // Save chat logic goes here
              await saveChatToLocalStorage(widget.prediction);
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
    if (result == true) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
    // If the user dismisses the dialog, return false
    // Otherwise, return the user's choice
    return result ?? false;
  }

  Future<void> saveChatToLocalStorage(String heading) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load existing chat threads from local storage
    String? chatJson = prefs.getString('AllMessages');
    List<dynamic> allMessages = chatJson != null ? jsonDecode(chatJson) : [];

    // Convert the list of ChatMessage objects to a list of maps
    List<Map<String, dynamic>> chatMessagesMapList =
        _messages.map((message) => message.toJson()).toList();

    // Add the current chat thread to the list
    Map<String, dynamic> chatThread = {
      'heading': heading,
      'messages': chatMessagesMapList,
    };
    allMessages.add(chatThread);

    // Save the updated list of chat threads to local storage
    await prefs.setString('AllMessages', jsonEncode(allMessages));
  }
}
