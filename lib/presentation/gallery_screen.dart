import 'package:flutter/material.dart';

import '../models/garbage_record.dart';
import '../services/storage_service.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GarbageRecord> records = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cloudRecords = await StorageService.getCloudRecords();

      if (!mounted) return;

      setState(() {
        records = cloudRecords;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refreshGallery() async {
    await _loadRecords();
  }

  Map<String, List<GarbageRecord>> _groupRecordsByDate() {
    final Map<String, List<GarbageRecord>> grouped = {};

    for (final record in records) {
      final date = record.timestamp.toLocal();

      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(record);
    }

    return grouped;
  }

  String _formatDate(String key) {
    final parts = key.split('-');

    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return 'Today';
    }

    if (recordDate == yesterday) {
      return 'Yesterday';
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final groupedRecords = _groupRecordsByDate();

    final dateKeys = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          'Gallery',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refreshGallery,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, groupedRecords, dateKeys),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, List<GarbageRecord>> groupedRecords,
    List<String> dateKeys,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  size: 45,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Unable to load gallery',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _loadRecords,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshGallery,
        color: colorScheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: _buildEmptyState(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshGallery,
      color: colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        itemCount: dateKeys.length,
        itemBuilder: (context, sectionIndex) {
          final dateKey = dateKeys[sectionIndex];
          final dateRecords = groupedRecords[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: sectionIndex == 0 ? 4 : 26,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(dateKey),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dateRecords.length} '
                        '${dateRecords.length == 1 ? 'photo' : 'photos'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dateRecords.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  return _buildPhotoCard(context, dateRecords[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 50,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Photos Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture a garbage photo and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your photos are stored securely in the cloud',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildPhotoCard(BuildContext context, GarbageRecord record) {
    final colorScheme = Theme.of(context).colorScheme;

    final localTime = record.timestamp.toLocal();

    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;

    final minute = localTime.minute.toString().padLeft(2, '0');

    final period = localTime.hour >= 12 ? 'PM' : 'AM';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoDetailScreen(record: record),
          ),
        );

        await _loadRecords();
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // ==================================================
              // IMAGE
              // ==================================================
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      record.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 45,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),

                    // Open image icon
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // PHOTO INFORMATION
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // AREA
                    // ------------------------------------------------
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_city_outlined,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            record.area.isEmpty ? 'Unknown Area' : record.area,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ------------------------------------------------
                    // COORDINATES
                    // ------------------------------------------------
                    Row(
                      children: [
                        Icon(
                          Icons.pin_drop_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${record.latitude.toStringAsFixed(4)}, '
                            '${record.longitude.toStringAsFixed(4)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ------------------------------------------------
                    // TIME
                    // ------------------------------------------------
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$hour:$minute $period',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
