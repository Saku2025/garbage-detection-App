import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Gets the user's current GPS position.
  ///
  /// Throws an exception if:
  /// - Location services are disabled
  /// - Location permission is denied
  /// - Location permission is permanently denied
  Future<Position> getCurrentLocation() async {
    // Check whether GPS/location service is enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    // Check permission.
    LocationPermission permission = await Geolocator.checkPermission();

    // Request permission if necessary.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    // Permission permanently denied.
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it from Settings.',
      );
    }

    // Get current position.
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Converts latitude and longitude into a readable area name.
  Future<String> getAreaName({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Unknown Area';
      }

      final place = placemarks.first;

      // Prefer the most specific locality/sub-locality available.
      final area =
          [place.subLocality, place.locality, place.subAdministrativeArea]
              .where((value) => value != null && value.trim().isNotEmpty)
              .map((value) => value!.trim())
              .firstOrNull;

      if (area != null) {
        return area;
      }

      // Fallback to administrative area.
      if (place.administrativeArea != null &&
          place.administrativeArea!.trim().isNotEmpty) {
        return place.administrativeArea!.trim();
      }

      return 'Unknown Area';
    } catch (_) {
      return 'Unknown Area';
    }
  }
}
