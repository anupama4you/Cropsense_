import 'package:flutter/material.dart';

class MessageDisplay extends StatefulWidget {
  const MessageDisplay({super.key});

  @override
  State<MessageDisplay> createState() => _MessageDisplayState();
}

class _MessageDisplayState extends State<MessageDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Messages'),
      ),
      backgroundColor: Colors.amberAccent,
    );
  }
}
