import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const AreWeThereYetApp());
}

class AreWeThereYetApp extends StatelessWidget {
  const AreWeThereYetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Are We There Yet?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const DestinationScreen(),
    );
  }
}

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  double targetLat = 50.8949;
  double targetLon = 4.3416;
  double alertRadius = 500;

  bool isTracking = false;
  String statusText = 'Klaar om te starten';
  String distanceText = '--';
  Timer? _trackingTimer;

  final TextEditingController latController = TextEditingController(text: '50.8949');
  final TextEditingController lonController = TextEditingController(text: '4.3416');
  final TextEditingController radiusController = TextEditingController(text: '500');

  @override
  void dispose() {
    _trackingTimer?.cancel();
    latController.dispose();
    lonController.dispose();
    radiusController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$targetLat,$targetLon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kan Google Maps niet openen')),
        );
      }
    }
  }

  void _toggleTracking() async {
    if (isTracking) {
      _stopTracking();
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            statusText = 'Locatiepermissie geweigerd!';
          });
          return;
        }
      }

      setState(() {
        targetLat = double.tryParse(latController.text) ?? 50.8949;
        targetLon = double.tryParse(lonController.text) ?? 4.3416;
        alertRadius = double.tryParse(radiusController.text) ?? 500;
        isTracking = true;
        statusText = 'Actief: Bezig met bewaken van je route...';
      });

      _checkLocationAndDistance();
      _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _checkLocationAndDistance();
      });
    }
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    setState(() {
      isTracking = false;
      statusText = 'Tracking gestopt.';
      distanceText = '--';
    });
  }

  Future<void> _checkLocationAndDistance() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLon,
      );

      setState(() {
        distanceText = '${distanceInMeters.toStringAsFixed(0)} meter';
      });

      if (distanceInMeters <= alertRadius) {
        _triggerAlarm(distanceInMeters);
      }
    } catch (e) {
      setState(() {
        statusText = 'GPS Fout: $e';
      });
    }
  }

  void _triggerAlarm(double distance) {
    _stopTracking();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 BESTEMMING BEREIKT!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Je bent op ${distance.toStringAsFixed(0)} meter van je bestemming! Tijd om wakker te worden of uit te stappen.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK / Sluiten'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Are We There Yet?', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bestemming Coördinaten', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            enabled: !isTracking,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lonController,
                            enabled: !isTracking,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: radiusController,
                      enabled: !isTracking,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Alarm straal (meters)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map, color: Colors.indigo),
                      label: const Text('Open in Google Maps'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isTracking ? Colors.green[50] : Colors.grey[100],
                border: Border.all(color: isTracking ? Colors.green.shade300 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(statusText, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: isTracking ? Colors.green[800] : Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Afstand tot doel: $distanceText', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _toggleTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: isTracking ? Colors.red : Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isTracking ? 'Bewaking Stoppen' : 'Start Reis & Alarm',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
