import 'package:latlong2/latlong.dart';
import 'package:top_places/services/location_service.dart';

/// A location without a GPS: [location], or [error] when the device would
/// refuse.
class FakeLocationService implements LocationService {
  FakeLocationService({this.location, this.error});

  final LatLng? location;
  final LocationException? error;

  @override
  Future<LatLng> currentLocation() async {
    if (error case final error?) throw error;
    return location!;
  }
}
