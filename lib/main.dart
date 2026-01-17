import 'package:flutter/material.dart';
import 'dart:math' as math;
// Platform import removed after removing external navigation
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
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
  final List<Tour> tours = [
    Tour(
      name: 'City Highlights',
      waypoints: [
        Waypoint(name: 'Central Park', info: 'A beautiful park in the city center.', audioUrl: '', lat: 40.785091, lon: -73.968285),
        Waypoint(name: 'Metropolitan Museum', info: 'Explore the city museum.', audioUrl: '', lat: 40.779437, lon: -73.963244),
      ],
    ),
    // Manchester City Centre demo tour
    Tour(
      name: 'Manchester City Centre',
      waypoints: [
        Waypoint(name: 'Piccadilly Gardens', info: 'Start at Piccadilly Gardens', audioUrl: '', lat: 53.4808, lon: -2.2360),
        Waypoint(name: 'Emmeline Pankhurst Statue', info: 'St Peter\'s Square memorial', audioUrl: '', lat: 53.4798, lon: -2.2426),
        Waypoint(name: 'Sinclair\'s Oyster Bar', info: 'Historic oyster bar near the markets', audioUrl: '', lat: 53.4809, lon: -2.2380),
      ],
    ),
    Tour(
      name: 'Historic Walk',
      waypoints: [
        Waypoint(name: 'Old Town Square', info: 'Historic heart of the city.', audioUrl: '', lat: 50.087465, lon: 14.421254),
      ],
    ),
    Tour(
      name: 'Riverside Stroll',
      waypoints: [
        Waypoint(name: 'River Jetty', info: 'Peaceful riverside views.', audioUrl: '', lat: 51.507351, lon: -0.127758),
      ],
    ),
    // Demo tour with closely spaced waypoints for GPS-based demo
    Tour(
      name: 'Demo Waterfront Loop',
      waypoints: [
        Waypoint(name: 'Pier A', info: 'Start of the demo loop.', audioUrl: '', lat: 40.700292, lon: -74.012084),
        Waypoint(name: 'Boardwalk', info: 'Scenic boardwalk.', audioUrl: '', lat: 40.701800, lon: -74.010200),
        Waypoint(name: 'Lookout', info: 'Nice lookout point.', audioUrl: '', lat: 40.703200, lon: -74.009000),
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
              // Background placeholder
              Container(
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
                  valueListenable: LocationSimulator.instance.position,
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
                LocationSimulator.instance.setPosition(waypoint.lat, waypoint.lon);
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
              valueListenable: LocationSimulator.instance.position,
              builder: (context, pos, _) {
                if (pos == Offset.zero) return Text('Current location unknown');
                final meters = distanceMeters(pos.dx, pos.dy, waypoint.lat, waypoint.lon);
                return Text('Distance to waypoint: ${(meters).toStringAsFixed(0)} m');
              },
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                LocationSimulator.instance.setPosition(waypoint.lat, waypoint.lon);
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
                    startLat: LocationSimulator.instance.position.value == Offset.zero ? waypoint.lat : LocationSimulator.instance.position.value.dx,
                    startLon: LocationSimulator.instance.position.value == Offset.zero ? waypoint.lon : LocationSimulator.instance.position.value.dy,
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
  final List<Waypoint> waypoints;
  Tour({required this.name, required this.waypoints});
}

class Waypoint {
  final String name;
  final String info;
  final String audioUrl;
  final double lat;
  final double lon;
  Waypoint({required this.name, required this.info, required this.audioUrl, required this.lat, required this.lon});
}

// Simple simulated location provider for demo purposes
class LocationSimulator {
  LocationSimulator._();
  static final instance = LocationSimulator._();
  // dx = lat, dy = lon
  final ValueNotifier<Offset> position = ValueNotifier(Offset.zero);
  void setPosition(double lat, double lon) => position.value = Offset(lat, lon);
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
      LocationSimulator.instance.setPosition(p.latitude, p.longitude);
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

