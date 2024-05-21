import 'dart:io';

import 'package:flutter/material.dart';

class PlantDisplay extends StatelessWidget {
  final String imagePath;

  PlantDisplay({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant Display'),
      ),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}
