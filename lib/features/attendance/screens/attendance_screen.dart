import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../widgets/attendance_button.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Position? position;
  String? locationError;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isMapReady = false;

  Future<void> getLocation() async {
    try {
      final currentPosition = await LocationService().getCurrentLocation();

      if (!mounted) return;

      setState(() {
        position = currentPosition;
        locationError = null;
      });

      // Move map to initial location if map is already ready
      if (_isMapReady) {
        _mapController.move(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          16.0,
        );
      }

      // Start listening to real-time location stream
      _startLocationUpdates();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        locationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update when moved 5 meters
      ),
    ).listen(
      (Position newPosition) {
        if (!mounted) return;
        setState(() {
          position = newPosition;
          locationError = null;
        });
      },
      onError: (error) {
        debugPrint("Error in location stream: $error");
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = position != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Peta Kehadiran",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasLocation
                              ? Colors.green.withValues(alpha: 0.1)
                              : (locationError != null
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasLocation
                              ? Icons.location_on
                              : (locationError != null
                                  ? Icons.error_outline
                                  : Icons.gps_fixed),
                          color: hasLocation
                              ? Colors.green
                              : (locationError != null
                                  ? Colors.red
                                  : Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasLocation
                                  ? "Lokasi Terdeteksi (Real-time)"
                                  : (locationError != null
                                      ? "Gagal Mengambil Lokasi"
                                      : "Mendeteksi Lokasi..."),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (locationError != null)
                              Text(
                                locationError!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              )
                            else if (hasLocation)
                              Text(
                                "Lat: ${position!.latitude.toStringAsFixed(6)}\nLng: ${position!.longitude.toStringAsFixed(6)}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (locationError != null)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: getLocation,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Map Container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // FlutterMap
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: hasLocation
                                ? LatLng(position!.latitude, position!.longitude)
                                : const LatLng(-6.200000, 106.816666), // Default Jakarta if null
                            initialZoom: 16.0,
                            onMapReady: () {
                              _isMapReady = true;
                              if (position != null) {
                                _mapController.move(
                                  LatLng(position!.latitude, position!.longitude),
                                  16.0,
                                );
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.jejak_hadir',
                            ),
                            if (hasLocation)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(position!.latitude, position!.longitude),
                                    width: 80,
                                    height: 80,
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 45,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // Loading State Overlay on Map
                        if (!hasLocation && locationError == null)
                          Container(
                            color: Colors.black.withValues(alpha: 0.05),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        // Recenter Button
                        if (hasLocation)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton.small(
                              heroTag: 'recenter_btn',
                              onPressed: () {
                                _mapController.move(
                                  LatLng(position!.latitude, position!.longitude),
                                  16.0,
                                );
                              },
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Attendance Buttons
              AttendanceButton(
                text: "Absen Masuk",
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/checkin',
                  );
                },
              ),
              const SizedBox(height: 12),
              AttendanceButton(
                text: "Absen Keluar",
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/checkout',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
