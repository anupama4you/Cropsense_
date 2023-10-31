import 'package:camera/camera.dart';
import 'package:cropsense/controller/scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized.value
              ? Stack(
                  children: [
                    Positioned.fill(
                        child: CameraPreview(controller.cameraController)),
                    Positioned(
                      top: 100,
                      right: 100,
                      // Add your additional UI elements here
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 4.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              color: Colors.white,
                              child: Text(controller.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(child: Text("Loading..."));
        },
      ),
    );
  }
}
