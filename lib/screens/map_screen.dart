import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_control/services/location_service.dart';
import 'package:speech_control/services/tracking_service.dart';
import 'package:speech_control/services/dangerZone_service.dart';
import 'package:speech_control/services/SOS_service.dart' as sos;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:html' as html; // For web notifications
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  final LocationService _locationService = LocationService();
  final TrackingService _trackingService = TrackingService();
  final DangerZoneService _dangerZoneService = DangerZoneService();
  final sos.SosService _sosService = sos.SosService();
  late StreamSubscription<Position> _locationSubscription;
  late StreamSubscription<List<DangerZone>> _dangerZoneSubscription;
  final MapController _mapController = MapController();
  bool _locationLoaded = false;
  bool _mapReady = false;
  List<DangerZone> _dangerZones = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInDangerZone = false;
  String? _emergencyContact;
  bool _isSendingSOS = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeLocation();
    _loadEmergencyContact();
    
    // Start tracking service which will handle both notifications and SOS
    _trackingService.startTracking();

    // Listen to danger zones updates
    _dangerZoneSubscription = _dangerZoneService.dangerZonesStream.listen((zones) {
      print("🔵 Received ${zones.length} danger zones from stream");
      setState(() {
        _dangerZones = zones;
      });
      _checkDangerZone(); // Check danger zone when zones update
    });

    _dangerZones = _dangerZoneService.dangerZones;
    print("🔵 Initially loaded ${_dangerZones.length} danger zones");
    
    // Initial check after zones are loaded
    Future.delayed(Duration(seconds: 1), () {
      _checkDangerZone();
    });
  }

  Future<void> _initializeNotifications() async {
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const iOSInitialize = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContact = '+91 8828617839';
    });
    print("📞 Loaded emergency contact: $_emergencyContact");
  }

  Future<void> _sendSOSAlert() async {
    if (_isSendingSOS || _currentLocation == null) {
      print("⚠️ Cannot send SOS: ${_isSendingSOS ? 'Already sending' : 'No location'}");
      return;
    }
    
    if (_emergencyContact == null) {
      print("⚠️ Cannot send SOS: No emergency contact set");
      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No emergency contact set. Please set one in settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSendingSOS = true);
    print("📱 Starting SOS alert process...");

    try {
      final success = await _sosService.sendSOS(
        userLocation: _currentLocation!,
        phoneNumber: _emergencyContact!,
      );

      if (success) {
        print("✅ SOS alert sent successfully");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SOS Alert sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to send SOS');
      }
    } catch (e) {
      print("❌ Error sending SOS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS alert: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingSOS = false);
    }
  }

  void _showDangerZoneNotification() async {
    print("🔔 Attempting to show notification");

    if (kIsWeb) {
      // For web, show a dialog instead of system notification
      _showFallbackAlert();
    } else {
      // Mobile notification
      const androidDetails = AndroidNotificationDetails(
        'danger_zone_channel',
        'Danger Zone Alerts',
        channelDescription: 'Notifications for when user enters danger zones',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iOSDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        0,
        'Danger Zone Alert',
        'You have entered a danger zone! Please be cautious.',
        notificationDetails,
      );
    }

    // Show a snackbar as additional visual feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Warning: You are in a danger zone!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  // Fallback method when notifications fail
  void _showFallbackAlert() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('⚠️ Danger Zone Alert'),
          content: Text(
            'You have entered a danger zone! Please be cautious.',
          ),
          backgroundColor: Colors.red.shade100,
          actions: [
            TextButton(
              child: Text(
                'Acknowledge',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void _checkDangerZone() {
    if (_currentLocation == null || _dangerZones.isEmpty) {
      print("🔍 Cannot check danger zone: ${_currentLocation == null ? 'No location' : 'No danger zones'}");
      return;
    }
    
    print("🔍 Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
    print("🔍 Is already in danger zone: $_isInDangerZone");
    print("🔍 Number of danger zones: ${_dangerZones.length}");

    bool isInAnyDangerZone = false;
    for (var zone in _dangerZones) {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        zone.center.latitude,
        zone.center.longitude,
      );
      
      print("🔍 Distance to zone: $distance meters, Zone radius: ${zone.radius} meters");

      if (distance <= zone.radius) {
        isInAnyDangerZone = true;
        print("⚠️ User is in danger zone!");
        break;
      }
    }

    // Only trigger alerts when entering a danger zone
    if (isInAnyDangerZone && !_isInDangerZone) {
      print("🚨 User entered danger zone - triggering alerts");
      // Add a small delay to ensure the state is updated
      Future.delayed(Duration(milliseconds: 100), () {
        // Show notification
        _showDangerZoneNotification();
        // Send SOS alert
        _sendSOSAlert();
      });
    } else if (isInAnyDangerZone) {
      print("🔍 User remains in danger zone - no new alerts");
    } else if (!isInAnyDangerZone && _isInDangerZone) {
      print("✅ User has left the danger zone");
    }

    setState(() {
      _isInDangerZone = isInAnyDangerZone;
    });
  }

  void _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          print("❌ Location permissions are permanently denied.");
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        // For testing, you can use either actual location or test coordinates
        // _currentLocation = LatLng(position.latitude, position.longitude);
        _currentLocation = LatLng(17.649746, 73.463903); // Test coordinates
        _locationLoaded = true;
      });

      if (_mapReady && _currentLocation != null) {
        _mapController.move(_currentLocation!, 15);
      }

      // Run an initial danger zone check
      _checkDangerZone();

      // Listen to location updates to update the UI and check danger zones
      _locationSubscription = _locationService.locationStream.listen(
        (Position position) {
          setState(() {
            // For testing, you can use either actual location or test coordinates
            // _currentLocation = LatLng(position.latitude, position.longitude);
            _currentLocation = LatLng(17.649746, 73.463903); // Test coordinates
          });
          
          // Check danger zone when location updates
          _checkDangerZone();
          
          // Update map center if needed
          if (_mapReady && _currentLocation != null) {
            _mapController.move(_currentLocation!, 15);
          }
        },
        onError: (error) {
          print("❌ Location Error: $error");
        },
      );
    } catch (e) {
      print("❌ Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Safety Map"),
        actions: [
          // Add a manual test button
          IconButton(
            icon: Icon(Icons.notifications),
            tooltip: 'Test Notification',
            onPressed: () {
              print("🔔 Manual notification test triggered");
              _showDangerZoneNotification();
            },
          ),
          IconButton(
            icon: Icon(Icons.sos),
            tooltip: 'Test SOS',
            onPressed: () {
              print("🚨 Manual SOS test triggered");
              _sendSOSAlert();
            },
          ),
          
          // Show danger zone indicator
          if (_isInDangerZone)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 4),
                    Text('In Danger Zone', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(17.649746, 73.463903),
                initialZoom: 15,
                onMapReady: () {
                  setState(() {
                    _mapReady = true;
                    // Check danger zone once map is ready
                    _checkDangerZone();
                  });
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                openStreetMapTileLayer,
    
                /// Show Real-Time Danger Zones
                CircleLayer(
                  circles: _dangerZones.map((zone) {
                    print("🔵 Drawing danger zone at ${zone.center.latitude},${zone.center.longitude}");
                    return CircleMarker(
                      point: zone.center,
                      color: Colors.red.withOpacity(0.3),
                      borderColor: Colors.red,
                      borderStrokeWidth: 3,
                      useRadiusInMeter: true,
                      radius: zone.radius,
                    );
                  }).toList(),
                ),
    
                /// Show User Location Marker
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_pin_circle,
                          size: 60,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Show SOS status indicator
          if (_isSendingSOS)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sending SOS Alert...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // Add a floating action button to manually test danger zone detection
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // For testing - force check danger zone
          _checkDangerZone();
        },
        child: Icon(Icons.refresh),
        tooltip: 'Check Danger Zone',
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    _dangerZoneSubscription.cancel();
    super.dispose();
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
);