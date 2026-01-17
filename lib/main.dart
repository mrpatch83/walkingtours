import 'package:flutter/material.dart';
import 'dart:math' as math;
// Platform import removed after removing external navigation
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';


void main() => runApp(WalkingTourApp());


class WalkingTourApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walking Tour',
      theme: ThemeData.dark(),
      home: TikTokFeedScreen(),
    );
  }
}

class TikTokFeedScreen extends StatefulWidget {
  @override
  _TikTokFeedScreenState createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends State<TikTokFeedScreen> {
  // Single Manchester tour with multiple waypoints starting at Piccadilly Gardens
  final List<Tour> tours = [
    Tour(
      name: 'Manchester City Centre',
      imageUrl: 'assets/images/manchester.svg',
      waypoints: [
        Waypoint(name: 'Piccadilly Gardens', info: 'Start at Piccadilly Gardens', audioUrl: '', lat: 53.4808, lon: -2.2360),
        Waypoint(name: 'Emmeline Pankhurst Statue', info: 'Emmeline Pankhurst memorial in St Peter\'s Square', audioUrl: '', lat: 53.4798, lon: -2.2426),
        Waypoint(name: 'Sinclair\'s Oyster Bar', info: 'Historic oyster bar near the markets', audioUrl: '', lat: 53.4809, lon: -2.2380),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: tours.length,
        itemBuilder: (context, index) {
          final tour = tours[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image (if provided) or placeholder gradient
              Positioned.fill(
                child: (tour.imageUrl != null && tour.imageUrl!.isNotEmpty)
                    ? (tour.imageUrl!.startsWith('assets/') && tour.imageUrl!.endsWith('.svg')
                        ? SvgPicture.asset(tour.imageUrl!, fit: BoxFit.cover)
                        : (tour.imageUrl!.startsWith('assets/')
                            ? Image.asset(tour.imageUrl!, fit: BoxFit.cover)
                            : Image.network(tour.imageUrl!, fit: BoxFit.cover)))
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.grey.shade900, Colors.black],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.location_on, size: 120, color: Colors.white24),
                        ),
                      ),
              ),

              // Bottom left info
              Positioned(
                left: 16,
                bottom: 60,
                right: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tour.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(tour.waypoints.map((w) => w.name).join(' • '), style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              // Right-side action buttons
              Positioned(
                right: 12,
                bottom: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(icon: Icons.favorite, label: '1.2k'),
                    SizedBox(height: 16),
                    _ActionButton(icon: Icons.comment, label: '24'),
                    SizedBox(height: 16),
                    _ActionButton(icon: Icons.share, label: ''),
                    SizedBox(height: 16),
                    _ActionButton(icon: Icons.bookmark, label: ''),
                  ],
                ),
              ),

              // Tap area to open details
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WaypointListScreen(tour: tour)),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: Colors.white),
        ),
        if (label.isNotEmpty) SizedBox(height: 6),
        if (label.isNotEmpty) Text(label, style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class WaypointListScreen extends StatelessWidget {
  final Tour tour;
  WaypointListScreen({required this.tour});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tour.name)),
      body: ListView.builder(
        itemCount: tour.waypoints.length,
        itemBuilder: (context, index) {
          final waypoint = tour.waypoints[index];
          return ListTile(
            title: Text(waypoint.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(waypoint.info),
                SizedBox(height: 6),
                ValueListenableBuilder<Offset>(
                  valueListenable: LocationService.instance.position,
                  builder: (context, pos, _) {
                    if (pos == Offset.zero) return Text('Location: unknown', style: TextStyle(fontSize: 12));
                    final meters = distanceMeters(pos.dx, pos.dy, waypoint.lat, waypoint.lon);
                    return Text('${(meters/1).toStringAsFixed(0)} m away', style: TextStyle(fontSize: 12));
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaypointDetailScreen(waypoint: waypoint),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.my_location),
              onPressed: () {
                // simulate user's device moving to this waypoint
                LocationService.instance.setPosition(waypoint.lat, waypoint.lon);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated location set to ${waypoint.name}')));
              },
            ),
          );
        },
      ),
    );
  }
}

class WaypointDetailScreen extends StatelessWidget {
  final Waypoint waypoint;
  WaypointDetailScreen({required this.waypoint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(waypoint.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(waypoint.info, style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Play audio for waypoint
              },
              child: Text('Play Audio'),
            ),
            SizedBox(height: 12),
            ValueListenableBuilder<Offset>(
              valueListenable: LocationService.instance.position,
              builder: (context, pos, _) {
                if (pos == Offset.zero) return Text('Current location unknown');
                final meters = distanceMeters(pos.dx, pos.dy, waypoint.lat, waypoint.lon);
                return Text('Distance to waypoint: ${(meters).toStringAsFixed(0)} m');
              },
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                LocationService.instance.setPosition(waypoint.lat, waypoint.lon);
              },
              child: Text('Simulate device at this waypoint'),
            ),
            SizedBox(height: 12),
            // External navigation removed: use In-App Navigate instead.
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MapNavigationScreen(
                    startLat: LocationService.instance.position.value == Offset.zero ? waypoint.lat : LocationService.instance.position.value.dx,
                    startLon: LocationService.instance.position.value == Offset.zero ? waypoint.lon : LocationService.instance.position.value.dy,
                    destLat: waypoint.lat,
                    destLon: waypoint.lon,
                  )),
                );
              },
              child: Text('In-App Navigate'),
            ),
          ],
        ),
      ),
    );
  }
}

class Tour {
  final String name;
  final String? imageUrl;
  final List<Waypoint> waypoints;
  Tour({required this.name, required this.waypoints, this.imageUrl});
}

class Waypoint {
  final String name;
  final String info;
  final String audioUrl;
  final double lat;
  final double lon;
  Waypoint({required this.name, required this.info, required this.audioUrl, required this.lat, required this.lon});
}

// Location service: uses device GPS when permission granted, otherwise supports manual simulation
class LocationService {
  LocationService._();
  static final instance = LocationService._();
  // dx = lat, dy = lon
  final ValueNotifier<Offset> position = ValueNotifier(Offset.zero);
  StreamSubscription<Position>? _sub;
  bool _usingDevice = false;

  Future<void> start() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _usingDevice = false;
        return;
      }
      _usingDevice = true;
      final locationSettings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);
      _sub = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((pos) {
        if (_usingDevice) {
          position.value = Offset(pos.latitude, pos.longitude);
        }
      });
    } catch (e) {
      _usingDevice = false;
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _usingDevice = false;
  }

  void setPosition(double lat, double lon) {
    // manual simulation overrides device updates until device tracking starts again
    _usingDevice = false;
    position.value = Offset(lat, lon);
  }
}

double degreesToRadians(double degrees) => degrees * (3.141592653589793 / 180.0);

// Haversine formula to compute distance in meters
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  final R = 6371000.0; // metres
  final dLat = degreesToRadians(lat2 - lat1);
  final dLon = degreesToRadians(lon2 - lon1);
  final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      math.cos(degreesToRadians(lat1)) * math.cos(degreesToRadians(lat2)) * (math.sin(dLon / 2) * math.sin(dLon / 2));
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

class MapNavigationScreen extends StatefulWidget {
  final double startLat, startLon, destLat, destLon;
  MapNavigationScreen({required this.startLat, required this.startLon, required this.destLat, required this.destLon});

  @override
  _MapNavigationScreenState createState() => _MapNavigationScreenState();
}

class _MapNavigationScreenState extends State<MapNavigationScreen> {
  final MapController _mapController = MapController();
  List<ll.LatLng> _route = [];
  Timer? _timer;
  int _stepIndex = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _computeStraightRoute();
    // start device location updates (will request permission if needed)
    LocationService.instance.start();
  }

  void _computeStraightRoute() {
    final start = ll.LatLng(widget.startLat, widget.startLon);
    final end = ll.LatLng(widget.destLat, widget.destLon);
    // generate N intermediate points
    final steps = 60;
    _route = List.generate(steps + 1, (i) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lon = start.longitude + (end.longitude - start.longitude) * t;
      return ll.LatLng(lat, lon);
    });
    // move map to start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(start, 15.0);
    });
  }

  void _startNavigation() {
    if (_isNavigating) return;
    _timer?.cancel();
    _stepIndex = 0;
    setState(() { _isNavigating = true; });
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_stepIndex >= _route.length) {
        timer.cancel();
        setState(() { _isNavigating = false; });
        return;
      }
      final p = _route[_stepIndex];
      LocationService.instance.setPosition(p.latitude, p.longitude);
      try {
        _mapController.move(p, _mapController.zoom);
      } catch (_) {}
      setState(() {});
      _stepIndex++;
    });
  }

  void _stopNavigation() {
    _timer?.cancel();
    _timer = null;
    setState(() { _isNavigating = false; });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = ll.LatLng(widget.startLat, widget.startLon);
    final end = ll.LatLng(widget.destLat, widget.destLon);
    return Scaffold(
      appBar: AppBar(title: Text('In-App Navigation')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(center: start, zoom: 15.0),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: ['a','b','c']),
          PolylineLayer(polylines: [Polyline(points: _route, color: Colors.blue, strokeWidth: 4.0)]),
          MarkerLayer(markers: [
            Marker(point: start, width: 40, height: 40, child: Icon(Icons.person_pin_circle, color: Colors.green, size: 36)),
            Marker(point: end, width: 40, height: 40, child: Icon(Icons.flag, color: Colors.red, size: 36)),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isNavigating ? _stopNavigation : _startNavigation,
        label: Text(_isNavigating ? 'Stop' : 'Start Navigation'),
        icon: Icon(_isNavigating ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}

