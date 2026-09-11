import 'package:camera/camera.dart';

class CameraService {
  Future<XFile?> takePicture() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera found on this device.');
    }

    final camera = cameras.first;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      final image = await controller.takePicture();

      return image;
    } finally {
      await controller.dispose();
    }
  }
}
