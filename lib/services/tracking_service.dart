import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'dangerZone_service.dart';
import 'notification_service.dart';
import 'sos_service.dart';

class TrackingService {
  final LocationService _locationService = LocationService();
  final DangerZoneService _dangerZoneService = DangerZoneService();
  final NotificationService _notificationService = NotificationService();
  final SosService _sosService = SosService();
  StreamSubscription<Position>? _locationSubscription;
  String? _emergencyContact;
  bool _isInDangerZone = false;

  TrackingService() {
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    _emergencyContact = prefs.getString('emergency_contact');
    print("📞 Loaded emergency contact: $_emergencyContact");
  }

  /// **Start listening for location updates**
  void startTracking() async {
    // Ensure we have the emergency contact
    if (_emergencyContact == null) {
      await _loadEmergencyContact();
    }

    _locationSubscription = _locationService.locationStream.listen((Position position) async {
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      bool wasInDangerZone = _isInDangerZone;
      _isInDangerZone = _dangerZoneService.isUserInDangerZone(userLocation);

      // Only trigger alerts when first entering the danger zone
      if (_isInDangerZone && !wasInDangerZone) {
        print("⚠️ User entered danger zone at $userLocation");
        
        // Show notification
        _notificationService.showNotification("You are in a danger zone!");

        // Send SOS if emergency contact is available
        if (_emergencyContact != null) {
          try {
            final success = await _sosService.sendSOS(
              userLocation: userLocation,
              phoneNumber: _emergencyContact!,
            );
            if (success) {
              print("✅ SOS alert sent successfully");
            } else {
              print("❌ Failed to send SOS alert");
            }
          } catch (e) {
            print("❌ Error sending SOS: $e");
          }
        } else {
          print("❌ No emergency contact available for SOS");
        }
      }
    });
  }

  /// **Stop tracking user location**
  void stopTracking() {
    _locationSubscription?.cancel();
  }
}
