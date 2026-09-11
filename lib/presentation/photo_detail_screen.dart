import 'package:flutter/material.dart';

import '../models/garbage_record.dart';
import '../services/storage_service.dart';

class PhotoDetailScreen extends StatelessWidget {
  final GarbageRecord record;

  const PhotoDetailScreen({super.key, required this.record});

  String _formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();

    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year.toString();

    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    final second = localDateTime.second.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute:$second';
  }

  Future<void> _deleteRecord(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Photo?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'This will permanently delete the photo and its saved location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (shouldDelete != true) return;

    try {
      await StorageService.deleteCloudRecord(record.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,

      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
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
            onPressed: () => _deleteRecord(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------------
            // CLOUD PHOTO
            // --------------------------------------------------------
            Container(
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
                    Image.network(
                      record.imagePath,
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
                    ),

                    // Cloud badge
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 26),

            // --------------------------------------------------------
            // SECTION TITLE
            // --------------------------------------------------------
            Text(
              'Detection Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------------
            // LATITUDE
            // --------------------------------------------------------
            _infoCard(
              context,
              icon: Icons.location_on_outlined,
              title: 'Latitude',
              value: record.latitude.toStringAsFixed(6),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------------
            // LONGITUDE
            // --------------------------------------------------------
            _infoCard(
              context,
              icon: Icons.location_on_outlined,
              title: 'Longitude',
              value: record.longitude.toStringAsFixed(6),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------------
            // AREA
            // --------------------------------------------------------
            _infoCard(
              context,
              icon: Icons.location_city_outlined,
              title: 'Area',
              value: record.area.isEmpty ? 'Unknown Area' : record.area,
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------------
            // CAPTURE TIME
            // --------------------------------------------------------
            _infoCard(
              context,
              icon: Icons.access_time_outlined,
              title: 'Captured At',
              value: _formatDateTime(record.timestamp),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------------
            // IMAGE STORAGE
            // --------------------------------------------------------
            _infoCard(
              context,
              icon: Icons.cloud_outlined,
              title: 'Image',
              value: 'Stored on Cloud',
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------------
            // INFORMATION NOTE
            // --------------------------------------------------------
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
                      'This photo, location, and capture time are '
                      'saved securely in your cloud account.',
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
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer),
          ),

          const SizedBox(width: 14),

          // Text
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
