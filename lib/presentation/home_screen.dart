import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? capturedImage;

  double? latitude;
  double? longitude;

  bool isLoadingLocation = false;

  String _userName = '';
  String _userEmail = '';

  final LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  Future<void> _loadUserDetails() async {
    final user = await AuthService.getCurrentUser();

    if (!mounted || user == null) return;

    setState(() {
      _userName = user['name']?.toString().trim() ?? '';
      _userEmail = user['email']?.toString().trim() ?? '';
    });
  }

  String _getInitials() {
    final name = _userName.trim();

    if (name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();

      if (parts.length == 1) {
        return parts[0][0].toUpperCase();
      }

      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    // Fallback for users without a name.
    final email = _userEmail.trim();

    if (email.isNotEmpty) {
      final emailName = email.split('@').first;

      if (emailName.length >= 2) {
        return emailName.substring(0, 2).toUpperCase();
      }

      return emailName[0].toUpperCase();
    }

    return 'U';
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> openCamera() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking location permission...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Location MUST be available before camera opens.
      final position = await locationService.getCurrentLocation();

      if (!mounted) return;

      // Get area name from GPS coordinates.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finding current area...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final area = await locationService.getAreaName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      // Open camera only after location is successfully obtained.
      final XFile? image = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );

      if (!mounted || image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading photo...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Upload image to Supabase Storage.
      final imagePath = await StorageService.uploadImage(File(image.path));

      // Create database record.
      final recordId = const Uuid().v4();

      final timestamp = DateTime.now();

      await StorageService.saveCloudRecord(
        id: recordId,
        imagePath: imagePath,
        latitude: position.latitude,
        longitude: position.longitude,
        area: area,
        timestamp: timestamp,
      );

      if (!mounted) return;

      setState(() {
        capturedImage = image;
        latitude = position.latitude;
        longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved successfully in $area.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to capture photo: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> getLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      final position = await locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await AuthService.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // PROFILE POPUP
  // ============================================================

  Future<void> _showProfileMenu() async {
    final colorScheme = Theme.of(context).colorScheme;

    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);

    await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(12, position.dy + 70, 12, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: 220,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    _getInitials(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _userEmail.isEmpty ? 'No email available' : _userEmail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const PopupMenuDivider(),

        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600, size: 21),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'logout') {
        logout();
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,

        // Avatar LEFT
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: GestureDetector(
            onTap: _showProfileMenu,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                _getInitials(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),

        title: Text(
          'Garbage Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),

        centerTitle: false,

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GalleryScreen()),
              );
            },
            icon: Icon(
              Icons.photo_library_outlined,
              color: colorScheme.primary,
            ),
            tooltip: 'Gallery',
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              Text(
                'Capture & Locate V1',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Capture garbage and record its exact location.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // CAMERA CARD
              // ------------------------------------------------
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: capturedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 45,
                                color: colorScheme.primary,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Text(
                              'No image captured',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'Take a photo of the garbage',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(capturedImage!.path),
                              fit: BoxFit.cover,
                            ),

                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Photo captured',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // CAMERA BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: openCamera,

                  icon: Icon(
                    capturedImage == null ? Icons.camera_alt : Icons.refresh,
                  ),

                  label: Text(
                    capturedImage == null ? 'Open Camera' : 'Capture Again',
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ------------------------------------------------
              // LOCATION CARD
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: colorScheme.primary,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'GPS coordinates',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Coordinates
                    if (latitude != null && longitude != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _coordinateRow(
                              'Latitude',
                              latitude!.toStringAsFixed(6),
                            ),

                            const SizedBox(height: 12),

                            _coordinateRow(
                              'Longitude',
                              longitude!.toStringAsFixed(6),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Location not captured yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Location button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isLoadingLocation ? null : getLocation,

                        icon: isLoadingLocation
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),

                        label: Text(
                          isLoadingLocation
                              ? 'Getting Location...'
                              : 'Get Current Location',
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // FOOTER
              // ------------------------------------------------
              Center(
                child: Text(
                  'Your location is only accessed when requested.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COORDINATE ROW
  // ============================================================

  Widget _coordinateRow(String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimaryContainer,
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
