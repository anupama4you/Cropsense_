import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatDetailPage extends StatelessWidget {
  final List<ChatMessage> chatThread;
  final ChatUser currentUser;
  final ChatUser gptChatUser;

  ChatDetailPage({
    required this.chatThread,
    required this.currentUser,
    required this.gptChatUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Completed Chat Thread',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: DashChat(
        currentUser: currentUser,
        messages: chatThread,
        messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromRGBO(0, 166, 126, 1),
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m) {
          // onSend does not do anything
        },
        inputOptions: const InputOptions(inputDisabled: true),
      ),
    );
  }
}
