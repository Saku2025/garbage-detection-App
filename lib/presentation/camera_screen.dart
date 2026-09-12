import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;

  bool isInitializing = true;
  bool isTakingPicture = false;

  XFile? capturedImage;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found');
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final newController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        controller = newController;
        isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isInitializing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
  }

  Future<void> captureImage() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        isTakingPicture) {
      return;
    }

    setState(() {
      isTakingPicture = true;
    });

    try {
      final image = await controller!.takePicture();

      if (!mounted) return;

      setState(() {
        capturedImage = image;
        isTakingPicture = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isTakingPicture = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to capture image: $e')));
    }
  }

  void retakeImage() {
    setState(() {
      capturedImage = null;
    });
  }

  void useImage() {
    if (capturedImage == null) return;

    Navigator.pop(context, capturedImage);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: capturedImage == null ? buildCameraView() : buildImagePreview(),
      ),
    );
  }

  // =========================
  // CAMERA VIEW
  // =========================

  Widget buildCameraView() {
    return Stack(
      children: [
        Positioned.fill(
          child: isInitializing
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : controller != null && controller!.value.isInitialized
              ? Center(child: CameraPreview(controller!))
              : const Center(
                  child: Text(
                    'Camera unavailable',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
        ),

        // Top bar
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              _circleButton(
                icon: Icons.close,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              const Expanded(
                child: Center(
                  child: Text(
                    'Capture Garbage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 48),
            ],
          ),
        ),

        // Capture button
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: captureImage,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTakingPicture ? Colors.grey : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 125,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Tap to capture',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // IMAGE PREVIEW
  // =========================

  Widget buildImagePreview() {
    return Stack(
      children: [
        // Captured image
        Positioned.fill(
          child: Image.file(File(capturedImage!.path), fit: BoxFit.contain),
        ),

        // Top bar
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              _circleButton(
                icon: Icons.close,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              const Expanded(
                child: Center(
                  child: Text(
                    'Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 48),
            ],
          ),
        ),

        // Bottom buttons
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: retakeImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: useImage,
                  icon: const Icon(Icons.check),
                  label: const Text('Use Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
