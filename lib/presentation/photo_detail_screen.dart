import 'package:flutter/material.dart';

import '../models/garbage_record.dart';
import '../services/storage_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final GarbageRecord record;

  // Optional image URL passed from GalleryScreen.
  // It is NOT required, so existing code remains compatible.
  final String? imagePath;

  // Optional starting image index.
  // Defaults to the first image.
  final int imageIndex;

  const PhotoDetailScreen({
    super.key,
    required this.record,
    this.imagePath,
    this.imageIndex = 0,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late List<String> _imageUrls;
  late PageController _pageController;

  int _currentIndex = 0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _imageUrls = List<String>.from(widget.record.imagePaths);

    // If GalleryScreen supplied a particular image URL,
    // start from that image.
    if (widget.imagePath != null &&
        widget.imagePath!.isNotEmpty &&
        _imageUrls.contains(widget.imagePath)) {
      _currentIndex = _imageUrls.indexOf(widget.imagePath!);
    } else if (_imageUrls.isNotEmpty) {
      _currentIndex = widget.imageIndex.clamp(0, _imageUrls.length - 1);
    } else {
      _currentIndex = 0;
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute:$second';
  }

  // ============================================================
  // DELETE CURRENT PHOTO
  // ============================================================

  Future<void> _deleteCurrentPhoto() async {
    if (_imageUrls.isEmpty || _isDeleting) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Photo?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            _imageUrls.length == 1
                ? 'This is the only photo in this report. '
                      'Deleting it will delete the complete report.'
                : 'Only the currently displayed photo will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await StorageService.deleteCloudImage(
        recordId: widget.record.id,
        imagePath: _imageUrls[_currentIndex],
      );

      if (!mounted) {
        return;
      }

      // Remove deleted image locally.
      setState(() {
        _imageUrls.removeAt(_currentIndex);

        if (_imageUrls.isEmpty) {
          _currentIndex = 0;
        } else if (_currentIndex >= _imageUrls.length) {
          _currentIndex = _imageUrls.length - 1;
        }
      });

      // If there are no photos left, the complete record was deleted.
      if (_imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
        return;
      }

      // Recreate PageController at the valid position.
      final oldController = _pageController;

      _pageController = PageController(initialPage: _currentIndex);

      oldController.dispose();

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete photo: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,

        title: const Text(
          'Photo Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),

        actions: [
          IconButton(
            onPressed: _isDeleting || _imageUrls.isEmpty
                ? null
                : _deleteCurrentPhoto,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete current photo',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // PHOTO VIEWER
            // ======================================================

            _buildPhotoViewer(context),

            const SizedBox(height: 14),

            // ======================================================
            // PHOTO COUNTER
            // ======================================================
            if (_imageUrls.length > 1)
              Center(
                child: Text(
                  '${_currentIndex + 1} / ${_imageUrls.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ======================================================
            // PHOTO INDICATOR DOTS
            // ======================================================
            if (_imageUrls.length > 1)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_imageUrls.length, (index) {
                    final isSelected = index == _currentIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),

            const SizedBox(height: 26),

            // ======================================================
            // SECTION TITLE
            // ======================================================
            Text(
              'Detection Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // AREA
            // ======================================================
            _infoCard(
              context,
              icon: Icons.location_city_outlined,
              title: 'Area',
              value: widget.record.area.isEmpty
                  ? 'Unknown Area'
                  : widget.record.area,
            ),

            const SizedBox(height: 12),

            // ======================================================
            // PIN CODE
            // ======================================================
            if (widget.record.pinCode.isNotEmpty)
              _infoCard(
                context,
                icon: Icons.markunread_mailbox_outlined,
                title: 'PIN Code',
                value: widget.record.pinCode,
              ),

            if (widget.record.pinCode.isNotEmpty) const SizedBox(height: 12),

            // ======================================================
            // ROAD NAME
            // ======================================================
            if (widget.record.roadName.isNotEmpty)
              _infoCard(
                context,
                icon: Icons.route_outlined,
                title: 'Road Name',
                value: widget.record.roadName,
              ),

            if (widget.record.roadName.isNotEmpty) const SizedBox(height: 12),

            // ======================================================
            // DESCRIPTION
            // ======================================================
            if (widget.record.description.isNotEmpty)
              _infoCard(
                context,
                icon: Icons.description_outlined,
                title: 'Description',
                value: widget.record.description,
              ),

            if (widget.record.description.isNotEmpty)
              const SizedBox(height: 12),

            // ======================================================
            // CAPTURE TIME
            // ======================================================
            _infoCard(
              context,
              icon: Icons.access_time_outlined,
              title: 'Captured At',
              value: _formatDateTime(widget.record.timestamp),
            ),

            const SizedBox(height: 12),

            // ======================================================
            // IMAGE STORAGE
            // ======================================================
            _infoCard(
              context,
              icon: Icons.cloud_outlined,
              title: 'Image',
              value: _imageUrls.length == 1
                  ? '1 photo stored on cloud'
                  : '${_imageUrls.length} photos stored on cloud',
            ),

            const SizedBox(height: 20),

            // ======================================================
            // INFORMATION NOTE
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onPrimaryContainer,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Swipe left or right to view all photos '
                      'from this report. The delete button removes '
                      'only the currently displayed photo.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO VIEWER
  // ============================================================

  Widget _buildPhotoViewer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_imageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 360,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ------------------------------------------------------
            // SWIPEABLE IMAGES
            // ------------------------------------------------------

            PageView.builder(
              controller: _pageController,
              itemCount: _imageUrls.length,
              onPageChanged: (index) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  _imageUrls[index],
                  width: double.infinity,
                  height: 360,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 60,
                      ),
                    );
                  },
                );
              },
            ),

            // ------------------------------------------------------
            // CLOUD BADGE
            // ------------------------------------------------------
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Cloud',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ------------------------------------------------------
            // LEFT ARROW
            // ------------------------------------------------------
            if (_imageUrls.length > 1 && _currentIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navigationButton(
                    icon: Icons.chevron_left,
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),

            // ------------------------------------------------------
            // RIGHT ARROW
            // ------------------------------------------------------
            if (_imageUrls.length > 1 && _currentIndex < _imageUrls.length - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navigationButton(
                    icon: Icons.chevron_right,
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION BUTTON
  // ============================================================

  Widget _navigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // ICON
          // --------------------------------------------------------

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer),
          ),

          const SizedBox(width: 14),

          // --------------------------------------------------------
          // TEXT
          // --------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
