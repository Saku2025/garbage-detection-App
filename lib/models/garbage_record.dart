class GarbageRecord {
  final String id;
  final String userId;
  final String area;
  final double latitude;
  final double longitude;
  final String pinCode;
  final String roadName;
  final String description;
  final List<String> imagePaths;
  final DateTime timestamp;

  GarbageRecord({
    required this.id,
    required this.userId,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.pinCode,
    required this.roadName,
    required this.description,
    required this.imagePaths,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'pin_code': pinCode,
      'road_name': roadName,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GarbageRecord.fromMap(Map<String, dynamic> map) {
    return GarbageRecord(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      area: map['area'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      pinCode: map['pin_code'] ?? '',
      roadName: map['road_name'] ?? '',
      description: map['description'] ?? '',
      imagePaths: List<String>.from(map['image_paths'] ?? []),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
