import 'dart:async';
import 'package:latlong2/latlong.dart';

class DangerZone {
  final LatLng center;
  final double radius; // in meters

  DangerZone({required this.center, required this.radius});
}

class DangerZoneService {
  final List<DangerZone> _dangerZones = [
    // Using larger radii to make zones more visible
    DangerZone(center: LatLng(17.649707, 73.463954), radius: 500), // Example 2
  ];

  final Distance _distance = Distance();
  final StreamController<List<DangerZone>> _dangerZonesController =
      StreamController<List<DangerZone>>.broadcast();

  DangerZoneService() {
    print("🔵 Initializing DangerZoneService with ${_dangerZones.length} zones");
    _dangerZonesController.add(_dangerZones); // Initialize with existing zones
  }

  /// **Check if user is inside a danger zone**
  bool isUserInDangerZone(LatLng userLocation) {
    for (var zone in _dangerZones) {
      double distanceToZone = _distance(zone.center, userLocation);
      if (distanceToZone <= zone.radius) {
        return true;
      }
    }
    return false;
  }

  /// **Get list of danger zones (Real-time Stream)**
  Stream<List<DangerZone>> get dangerZonesStream =>
      _dangerZonesController.stream;

  /// **Get list of danger zones (Once)**
  List<DangerZone> get dangerZones => _dangerZones;

  /// **Add a new danger zone**
  void addDangerZone(LatLng center, double radius) {
    _dangerZones.add(DangerZone(center: center, radius: radius));
    _dangerZonesController.add(_dangerZones); // Notify listeners
  }

  /// **Remove a danger zone**
  void removeDangerZone(LatLng center) {
    _dangerZones.removeWhere((zone) => zone.center == center);
    _dangerZonesController.add(_dangerZones); // Notify listeners
  }

  /// **Dispose stream controller when not needed**
  void dispose() {
    _dangerZonesController.close();
  }
}
