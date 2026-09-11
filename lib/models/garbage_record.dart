class GarbageRecord {
  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String area;
  final DateTime timestamp;

  GarbageRecord({
    required this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GarbageRecord.fromMap(Map<dynamic, dynamic> map) {
    return GarbageRecord(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      area: map['area']?.toString() ?? 'Unknown Area',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
