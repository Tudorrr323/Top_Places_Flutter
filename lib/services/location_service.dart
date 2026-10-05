import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Why the location is not available.
enum LocationProblem {
  serviceOff,
  denied,
  deniedForever,
  blockedByBrowser,
  accuracyOff,
  notFound,
}

/// The location is not available; the screen says why, in its language.
class LocationException implements Exception {
  const LocationException(this.problem, {this.openSettings});

  final LocationProblem problem;

  /// Opens the settings where the user can fix it, or null when there are
  /// none to open (on the web, the browser asks again).
  final Future<bool> Function()? openSettings;

  @override
  String toString() => 'LocationException($problem)';
}

/// Where the device is. An interface, so that the tests can use a fake.
abstract class LocationService {
  /// Asks for the permission the first time, then finds the device. Throws
  /// a [LocationException] when it can't.
  Future<LatLng> currentLocation();
}

/// The location from the device: the GPS on a phone, the browser on the
/// web, Windows' location service on a PC.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LatLng> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(
        LocationProblem.serviceOff,
        openSettings: kIsWeb ? null : Geolocator.openLocationSettings,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // The system asks the user here.
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationProblem.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      // The system no longer asks: only the settings can change it.
      throw kIsWeb
          ? const LocationException(LocationProblem.blockedByBrowser)
          : const LocationException(
              LocationProblem.deniedForever,
              openSettings: Geolocator.openAppSettings,
            );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on LocationServiceDisabledException {
      // On Android, Google first asks to turn on "Location Accuracy";
      // refused, there is no location.
      throw const LocationException(LocationProblem.accuracyOff);
    } on Exception {
      // A timeout, or the location turned off in the meantime.
      throw const LocationException(LocationProblem.notFound);
    }
  }
}
