import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SosService {
  final String _sosUrl = 'http://127.0.0.1:8000/api/sos/';

  /// Send SOS alert with user's location and emergency contact
  Future<bool> sendSOS({
    required LatLng userLocation,
    required String phoneNumber,
  }) async {
    try {
      print("📍 Sending SOS - Location: ${userLocation.latitude}, ${userLocation.longitude}");
      print("📞 Emergency Contact: $phoneNumber");

      final response = await http.post(
        Uri.parse(_sosUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": phoneNumber,
          "latitude": userLocation.latitude,
          "longitude": userLocation.longitude,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ SOS alert sent successfully");
        return true;
      } else {
        print("❌ Failed to send SOS alert: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error sending SOS alert: $e");
      return false;
    }
  }

  /// Check if user is in any danger zone
  bool isInDangerZone(LatLng userLocation, List<DangerZone> dangerZones) {
    for (var zone in dangerZones) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        userLocation,
        zone.center,
      );
      
      if (distance <= zone.radius) {
        print("⚠️ User entered danger zone at ${zone.center}");
        return true;
      }
    }
    return false;
  }
}

/// Model class for Danger Zone
class DangerZone {
  final LatLng center;
  final double radius;

  DangerZone({
    required this.center,
    required this.radius,
  });
}
