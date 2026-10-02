import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/location_service.dart';
import '../services/storage_service.dart';
import 'camera_screen.dart';

class ReportFormScreen extends StatefulWidget {
  final XFile firstImage;

  const ReportFormScreen({super.key, required this.firstImage});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final LocationService locationService = LocationService();

  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController roadNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<XFile> images = [];

  double? latitude;
  double? longitude;
  String area = 'Detecting area...';

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    images.add(widget.firstImage);

    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await locationService.getCurrentLocation();

      final detectedArea = await locationService.getAreaName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        area = detectedArea;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to get location: $e')));
    }
  }

  Future<void> _addAnotherPhoto() async {
    if (images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed per report.')),
      );
      return;
    }

    final XFile? image = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (!mounted || image == null) return;

    setState(() {
      images.add(image);
    });
  }

  void _removePhoto(int index) {
    if (images.length == 1) return;

    setState(() {
      images.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is not available yet.')),
      );
      return;
    }

    if (pinCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter PIN code.')));
      return;
    }

    if (roadNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter road name.')));
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final recordId = const Uuid().v4();

      await StorageService.createGarbageReport(
        recordId: recordId,
        images: images.map((image) => File(image.path)).toList(),
        latitude: latitude!,
        longitude: longitude!,
        area: area,
        pinCode: pinCodeController.text.trim(),
        roadName: roadNameController.text.trim(),
        description: descriptionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Garbage report uploaded successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    pinCodeController.dispose();
    roadNameController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Garbage Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length + (images.length < 5 ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == images.length) {
                          return _addPhotoButton();
                        }

                        return _photoItem(index);
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${images.length}/5 photos',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 25),

                  _locationCard(),

                  const SizedBox(height: 25),

                  TextField(
                    controller: pinCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'PIN Code',
                      hintText: 'Enter PIN code',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: roadNameController,
                    decoration: const InputDecoration(
                      labelText: 'Road Name',
                      hintText: 'Enter road name',
                      prefixIcon: Icon(Icons.route),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the garbage...',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : _submitReport,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        isSubmitting ? 'Uploading...' : 'Submit Report',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _photoItem(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(images[index].path),
            width: 110,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoButton() {
    return GestureDetector(
      onTap: images.length < 5 ? _addAnotherPhoto : null,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 30, color: Colors.green),
            SizedBox(height: 5),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _locationRow('Area', area, Icons.location_city),
          const Divider(),
          _locationRow(
            'Latitude',
            latitude?.toStringAsFixed(6) ?? '-',
            Icons.location_on,
          ),
          const Divider(),
          _locationRow(
            'Longitude',
            longitude?.toStringAsFixed(6) ?? '-',
            Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _locationRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    );
  }
}
