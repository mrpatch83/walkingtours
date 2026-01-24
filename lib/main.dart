import 'package:flutter/material.dart';
import 'dart:math' as math;
// Platform import removed after removing external navigation
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// conditional import for web storage
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage.dart';
// conditional web file picker
import 'web_file_picker_stub.dart' if (dart.library.html) 'web_file_picker_web.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart';


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
  List<Tour> tours = [
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

  final _webStorage = WebStorage();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final saved = _webStorage.loadTours();
      if (saved != null) {
        try {
          final decoded = json.decode(saved) as List<dynamic>;
          final loaded = decoded.map((e) => Tour.fromJson(e as Map<String, dynamic>)).toList();
          // merge loaded tours with defaults: append any new tours that don't match by name
          for (var lt in loaded) {
            if (!tours.any((t) => t.name == lt.name)) tours.add(lt);
          }
        } catch (_) {}
      }
    }

    // Load tours from asset if present (allows bundling user-updated tours into the app)
    try {
      rootBundle.loadString('assets/tours.json').then((s) {
        try {
          final decoded = json.decode(s) as List<dynamic>;
          final loaded = decoded.map((e) => Tour.fromJson(e as Map<String, dynamic>)).toList();
          setState(() {
            for (var lt in loaded) {
              if (!tours.any((t) => t.name == lt.name)) tours.add(lt);
            }
          });
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tours'), actions: [
        if (kIsWeb)
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TourEditorScreen(initialTours: tours, onSave: (list) {
              setState(() {
                // merge saved/edited list into existing tours by name
                for (var nt in list) {
                  if (!tours.any((t) => t.name == nt.name)) tours.add(nt);
                }
              });
              _webStorage.saveTours(json.encode(tours.map((t) => t.toJson()).toList()));
            }))),
            icon: Icon(Icons.edit, color: Colors.white),
            label: Text('Edit Tours', style: TextStyle(color: Colors.white)),
          ),
      ]),
      body: ListView.builder(
        itemCount: tours.length,
        itemBuilder: (context, index) {
          final tour = tours[index];
          return ListTile(
            leading: tour.imageUrl != null ? SvgPicture.asset(tour.imageUrl!, width: 56, height: 56) : null,
            title: Text(tour.name),
            subtitle: Text(tour.waypoints.map((w) => w.name).join(' • ')),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WaypointListScreen(tour: tour))),
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
      appBar: AppBar(
        title: Text(tour.name),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TourNavigationScreen(tour: tour)));
            },
            icon: Icon(Icons.directions_walk, color: Colors.white),
            label: Text('Start Tour', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

class TourNavigationScreen extends StatefulWidget {
  final Tour tour;
  TourNavigationScreen({required this.tour});

  @override
  _TourNavigationScreenState createState() => _TourNavigationScreenState();
}

class _TourNavigationScreenState extends State<TourNavigationScreen> {
  final MapController _mapController = MapController();
  int _currentIndex = 0;
  bool _navigating = false;
  VoidCallback? _listener;

  // per-leg route and maneuvers persisted for the active leg
  List<ll.LatLng> _legRoute = [];
  List<Maneuver> _legManeuvers = [];
  static const MethodChannel _audioChannel = MethodChannel('com.example.walking_tour_app/audio');

  @override
  void initState() {
    super.initState();
    LocationService.instance.start();
    _listener = () { _onPositionChanged(); };
    LocationService.instance.position.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) LocationService.instance.position.removeListener(_listener!);
    LocationService.instance.stop();
    super.dispose();
  }

  void _start() {
    setState(() {
      _navigating = true;
    });
    _computeLegRouteAndManeuvers();
  }

  void _stop() {
    setState(() { _navigating = false; });
  }

  void _skip() {
    if (_currentIndex < widget.tour.waypoints.length - 1) {
      setState(() {
        _currentIndex++;
        _computeLegRouteAndManeuvers();
      });
    }
  }

  Future<void> _arrived() async {
    final waypoint = widget.tour.waypoints[_currentIndex];
    final url = waypoint.audioUrl;
    // Try platform audio playback (iOS AVPlayer). If it fails or no url, just advance.
    try {
      if (url.isNotEmpty) {
        await _audioChannel.invokeMethod('play', {'url': url});
      }
    } catch (e) {
      // ignore playback errors
    }

    // Advance to next waypoint (or finish)
    if (_currentIndex < widget.tour.waypoints.length - 1) {
      setState(() {
        _currentIndex++;
        _legRoute = [];
        _legManeuvers = [];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _computeLegRouteAndManeuvers());
    } else {
      setState(() { _navigating = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tour complete')));
    }
  }

  static const MethodChannel _routingChannel = MethodChannel('com.example.walking_tour_app/routing');

  Future<void> _computeLegRouteAndManeuvers() async {
    final target = widget.tour.waypoints[_currentIndex];
    final pos = LocationService.instance.position.value;
    final start = (pos != Offset.zero) ? ll.LatLng(pos.dx, pos.dy) : ll.LatLng(target.lat, target.lon);
    final end = ll.LatLng(target.lat, target.lon);

    // Try to request a routed polyline from iOS MapKit (Apple Maps). Fallback to straight line if unavailable.
    List<ll.LatLng> routePoints = [];
    try {
      final resp = await _routingChannel.invokeMethod('getRoute', {
        'startLat': start.latitude,
        'startLon': start.longitude,
        'endLat': end.latitude,
        'endLon': end.longitude,
      });
      if (resp is List) {
        for (var item in resp) {
          if (item is List && item.length >= 2) {
            final lat = (item[0] as num).toDouble();
            final lon = (item[1] as num).toDouble();
            routePoints.add(ll.LatLng(lat, lon));
          }
        }
      }
    } catch (e) {
      routePoints = [];
    }

    if (routePoints.isEmpty) {
      // fallback straight-line interpolation
      final steps = 60;
      routePoints = List.generate(steps + 1, (i) {
        final t = i / steps;
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lon = start.longitude + (end.longitude - start.longitude) * t;
        return ll.LatLng(lat, lon);
      });
    }

    _legRoute = routePoints;
    _legManeuvers = computeManeuvers(_legRoute);
    setState(() {});
  }

  void _onPositionChanged() {
    final pos = LocationService.instance.position.value;
    if (pos == Offset.zero) return;
    final current = ll.LatLng(pos.dx, pos.dy);
    // ensure we have maneuvers for the active leg while navigating
    if (_navigating && _legManeuvers.isEmpty) {
      _computeLegRouteAndManeuvers();
    }
    // update maneuvers passed
    _updateLegManeuver(current);
    // check arrival
    final target = widget.tour.waypoints[_currentIndex];
    final meters = distanceMeters(current.latitude, current.longitude, target.lat, target.lon);
    if (_navigating && meters <= 15.0) {
      if (_currentIndex < widget.tour.waypoints.length - 1) {
        setState(() {
          _currentIndex++;
          _legRoute = [];
          _legManeuvers = [];
        });
        // compute next leg after small delay to allow UI to update
        WidgetsBinding.instance.addPostFrameCallback((_) => _computeLegRouteAndManeuvers());
      } else {
        setState(() { _navigating = false; });
      }
    }
    setState(() {});
  }

  void _updateLegManeuver(ll.LatLng p) {
    for (var m in _legManeuvers) {
      if (!m.passed) {
        final d = distanceMeters(p.latitude, p.longitude, m.point.latitude, m.point.longitude);
        if (d <= 12.0) m.passed = true;
        else break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.tour.waypoints[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text('Tour: ${widget.tour.name} (${_currentIndex+1}/${widget.tour.waypoints.length})')),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<Offset>(
              valueListenable: LocationService.instance.position,
              builder: (context, pos, _) {
                final hasPos = pos != Offset.zero;
                final current = hasPos ? ll.LatLng(pos.dx, pos.dy) : ll.LatLng(target.lat, target.lon);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try { _mapController.move(current, 19.0); } catch (_) {}
                });

                final targetLatLng = ll.LatLng(target.lat, target.lon);
                final polyPoints = _legRoute.isNotEmpty ? _legRoute : (() {
                  final start = current;
                  final end = targetLatLng;
                  final steps = 60;
                  return List.generate(steps + 1, (i) {
                    final t = i / steps;
                    final lat = start.latitude + (end.latitude - start.latitude) * t;
                    final lon = start.longitude + (end.longitude - start.longitude) * t;
                    return ll.LatLng(lat, lon);
                  });
                })();

                // split polyline into passed and remaining segments so user sees progress
                final passedRemaining = (() {
                  if (_legManeuvers.isEmpty) return <List<ll.LatLng>>[[], polyPoints];
                  final next = _legManeuvers.firstWhere((m) => !m.passed, orElse: () => _legManeuvers.last);
                  var splitIndex = polyPoints.length;
                  for (var i = 0; i < polyPoints.length; i++) {
                    final d = distanceMeters(polyPoints[i].latitude, polyPoints[i].longitude, next.point.latitude, next.point.longitude);
                    if (d < 5.0) { splitIndex = i; break; }
                  }
                  final passed = (splitIndex > 0) ? polyPoints.sublist(0, splitIndex + 1) : <ll.LatLng>[];
                  final remaining = (splitIndex < polyPoints.length) ? polyPoints.sublist(splitIndex) : <ll.LatLng>[];
                  return <List<ll.LatLng>>[passed, remaining];
                })();

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: current, zoom: 19.0, maxZoom: 20.0, minZoom: 14.0),
                  children: [
                    TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: ['a','b','c']),
                    PolylineLayer(polylines: [
                      if (passedRemaining[0].isNotEmpty) Polyline(points: passedRemaining[0], color: Colors.grey.shade500, strokeWidth: 4.0),
                      if (passedRemaining[1].isNotEmpty) Polyline(points: passedRemaining[1], color: Colors.blue, strokeWidth: 4.0),
                    ]),
                    MarkerLayer(markers: [
                      Marker(point: targetLatLng, width: 40, height: 40, child: Icon(Icons.flag, color: Colors.red, size: 36)),
                      if (hasPos) Marker(point: current, width: 40, height: 40, child: Icon(Icons.person_pin_circle, color: Colors.green, size: 36)),
                    ]),
                  ],
                );
              },
            ),
          ),

          // persistent maneuver bar for the active leg
          Builder(builder: (context) {
            final pos = LocationService.instance.position.value;
            if (!_navigating || pos == Offset.zero || _legManeuvers.isEmpty) return SizedBox.shrink();
            final nextIndex = _legManeuvers.indexWhere((m) => !m.passed);
            final next = nextIndex >= 0 ? _legManeuvers[nextIndex] : _legManeuvers.last;
            final second = (nextIndex >= 0 && nextIndex + 1 < _legManeuvers.length) ? _legManeuvers[nextIndex + 1] : null;
            final d = distanceMeters(pos.dx, pos.dy, next.point.latitude, next.point.longitude);
            return Container(
              color: Colors.black87,
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.navigation, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(next.instruction, style: TextStyle(color: Colors.white, fontSize: 16)),
                        if (second != null) SizedBox(height: 6),
                        if (second != null) Text('Then: ${second.instruction}', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('${d.toStringAsFixed(0)} m', style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }),

          SafeArea(
            bottom: true,
            child: Material(
              color: Colors.black87,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next: ${target.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    ValueListenableBuilder<Offset>(
                      valueListenable: LocationService.instance.position,
                      builder: (context, pos, _) {
                        if (pos == Offset.zero) return Text('Waiting for device location...', style: TextStyle(color: Colors.white70));
                        final m = distanceMeters(pos.dx, pos.dy, target.lat, target.lon);
                        return Text('Distance: ${m.toStringAsFixed(0)} m', style: TextStyle(color: Colors.white70));
                      },
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _navigating ? _stop : _start,
                          icon: Icon(_navigating ? Icons.pause : Icons.play_arrow),
                          label: Text(_navigating ? 'Pause' : 'Start'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(onPressed: _skip, icon: Icon(Icons.skip_next), label: Text('Skip')),
                        SizedBox(width: 12),
                        ElevatedButton.icon(onPressed: _arrived, icon: Icon(Icons.check_circle), label: Text('Arrived')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

// Simple web tour editor screen (web-only features enabled via WebStorage)
class TourEditorScreen extends StatefulWidget {
  final void Function(List<Tour>)? onSave;
  final List<Tour>? initialTours;
  TourEditorScreen({this.onSave, this.initialTours});
  @override
  _TourEditorScreenState createState() => _TourEditorScreenState();
}

class _TourEditorScreenState extends State<TourEditorScreen> {
  List<Tour> _tours = [];
  final _webStorage = WebStorage();

  @override
  void initState() {
    super.initState();
    // start with initial tours passed from app (defaults), make a deep copy
    if (widget.initialTours != null) {
      _tours = widget.initialTours!.map((t) => Tour(name: t.name, imageUrl: t.imageUrl, waypoints: t.waypoints.map((w) => Waypoint(name: w.name, info: w.info, audioUrl: w.audioUrl, lat: w.lat, lon: w.lon)).toList())).toList();
    }
    // then load any saved tours from web storage and append any new ones
    final saved = _webStorage.loadTours();
    if (saved != null) {
      try {
        final decoded = json.decode(saved) as List<dynamic>;
        final loaded = decoded.map((e) => Tour.fromJson(e as Map<String, dynamic>)).toList();
        for (var lt in loaded) {
          if (!_tours.any((t) => t.name == lt.name)) _tours.add(lt);
        }
      } catch (_) {}
    }
  }

  void _addTour() {
    setState(() { _tours.add(Tour(name: 'New Tour', imageUrl: null, waypoints: [])); });
  }

  void _saveAll() {
    final jsonStr = json.encode(_tours.map((t) => t.toJson()).toList());
    _webStorage.saveTours(jsonStr);
    _webStorage.downloadTours(jsonStr, 'tours.json');
    if (widget.onSave != null) widget.onSave!(_tours);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tours saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tour Editor'), actions: [
        IconButton(onPressed: _addTour, icon: Icon(Icons.add), tooltip: 'Add Tour'),
      ]),
      body: ListView.builder(
        itemCount: _tours.length,
        itemBuilder: (context, idx) {
          final tour = _tours[idx];
          return Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  TextFormField(initialValue: tour.name, onChanged: (v) => tour.name == v ? null : tour.name = v),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: tour.imageUrl ?? '',
                    decoration: InputDecoration(labelText: 'Image URL or asset path (optional)'),
                    onChanged: (v) => tour.imageUrl = v.trim().isEmpty ? null : v.trim(),
                  ),
                  SizedBox(height: 8),
                  if (tour.imageUrl != null && tour.imageUrl!.isNotEmpty)
                    Builder(builder: (c) {
                      final url = tour.imageUrl!;
                      if (url.startsWith('http')) {
                        if (url.toLowerCase().endsWith('.svg')) return SvgPicture.network(url, height: 80);
                        return Image.network(url, height: 80, errorBuilder: (_, __, ___) => Text('Preview not available'));
                      } else {
                        try {
                          return SvgPicture.asset(url, height: 80);
                        } catch (_) {
                          return Text('Preview not available for asset path');
                        }
                      }
                    }),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!kIsWeb) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload is available on web only')));
                        return;
                      }
                      final dataUrl = await pickImageFile();
                      if (dataUrl != null) setState(() { tour.imageUrl = dataUrl; });
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Image (web)'),
                  ),
                  SizedBox(height: 8),
                  ...tour.waypoints.asMap().entries.map((e) {
                    final i = e.key; final w = e.value;
                    return ListTile(
                      title: TextFormField(initialValue: w.name, onChanged: (v) => w.name == v ? null : w.name = v),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(initialValue: w.info, onChanged: (v) => w.info == v ? null : w.info = v),
                          Row(children: [
                            Expanded(child: TextFormField(initialValue: w.lat.toString(), onChanged: (v) { final d = double.tryParse(v) ?? w.lat; w.lat = d; })),
                            SizedBox(width: 8),
                            Expanded(child: TextFormField(initialValue: w.lon.toString(), onChanged: (v) { final d = double.tryParse(v) ?? w.lon; w.lon = d; })),
                          ]),
                          TextButton(onPressed: () { setState(() { tour.waypoints.removeAt(i); }); }, child: Text('Remove waypoint'))
                        ],
                      ),
                    );
                  }),
                  TextButton(onPressed: () { setState(() { tour.waypoints.add(Waypoint(name: 'WP', info: '', audioUrl: '', lat: 0.0, lon: 0.0)); }); }, child: Text('Add waypoint')),
                  SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(onPressed: _addTour, icon: Icon(Icons.add), label: Text('Add Tour')),
          SizedBox(height: 8),
          FloatingActionButton.extended(onPressed: _saveAll, icon: Icon(Icons.save), label: Text('Save & Export')),
        ],
      ),
    );
  }
}

class Tour {
  String name;
  String? imageUrl;
  final List<Waypoint> waypoints;
  Tour({required this.name, required this.waypoints, this.imageUrl});

  Map<String, dynamic> toJson() => {
        'name': name,
        'imageUrl': imageUrl,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
      };

  static Tour fromJson(Map<String, dynamic> j) => Tour(
        name: j['name'] ?? 'Untitled',
        imageUrl: j['imageUrl'],
        waypoints: (j['waypoints'] as List<dynamic>? ?? []).map((e) => Waypoint.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Waypoint {
  String name;
  String info;
  String audioUrl;
  double lat;
  double lon;
  Waypoint({required this.name, required this.info, required this.audioUrl, required this.lat, required this.lon});

  Map<String, dynamic> toJson() => {
        'name': name,
        'info': info,
        'audioUrl': audioUrl,
        'lat': lat,
        'lon': lon,
      };

  static Waypoint fromJson(Map<String, dynamic> j) => Waypoint(
        name: j['name'] ?? '',
        info: j['info'] ?? '',
        audioUrl: j['audioUrl'] ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (j['lon'] as num?)?.toDouble() ?? 0.0,
      );
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

// Simple maneuver model and helpers for turn-by-turn
class Maneuver {
  final ll.LatLng point;
  final String instruction;
  bool passed;
  Maneuver({required this.point, required this.instruction, this.passed = false});
}

double _bearingBetween(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = degreesToRadians(lat1);
  final phi2 = degreesToRadians(lat2);
  final lambda1 = degreesToRadians(lon1);
  final lambda2 = degreesToRadians(lon2);
  final y = math.sin(lambda2 - lambda1) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(lambda2 - lambda1);
  final theta = math.atan2(y, x);
  return (theta * 180.0 / 3.141592653589793 + 360.0) % 360.0;
}

double _angleDiff(double a, double b) {
  var d = (b - a + 540.0) % 360.0 - 180.0;
  return d;
}

String _bearingToCompass(double bearing) {
  // 16-point compass
  final List<String> points = [
    'north', 'north-northeast', 'northeast', 'east-northeast',
    'east', 'east-southeast', 'southeast', 'south-southeast',
    'south', 'south-southwest', 'southwest', 'west-southwest',
    'west', 'west-northwest', 'northwest', 'north-northwest'
  ];
  final idx = ((bearing + 11.25) % 360) / 22.5;
  return points[idx.floor() % 16];
}

List<Maneuver> computeManeuvers(List<ll.LatLng> route) {
  final List<Maneuver> out = [];
  if (route.length < 2) return out;
  // first instruction: head in initial bearing towards destination
  final initialBearing = _bearingBetween(route[0].latitude, route[0].longitude, route[1].latitude, route[1].longitude);
  final initialDir = _bearingToCompass(initialBearing);
  out.add(Maneuver(point: route.last, instruction: 'Head $initialDir towards destination'));
  // compute bearings for consecutive segments
  final bearings = List<double>.filled(route.length - 1, 0.0);
  for (var i = 0; i < route.length - 1; i++) {
    bearings[i] = _bearingBetween(route[i].latitude, route[i].longitude, route[i + 1].latitude, route[i + 1].longitude);
  }
  const threshold = 15.0; // degrees (more sensitive to gentler turns)
  ll.LatLng? lastAddedPoint;
  for (var i = 0; i < bearings.length - 1; i++) {
    final diff = _angleDiff(bearings[i], bearings[i + 1]);
    if (diff.abs() >= threshold) {
      final idx = i + 1;
      final point = route[idx];
      if (lastAddedPoint != null) {
        final d = distanceMeters(lastAddedPoint.latitude, lastAddedPoint.longitude, point.latitude, point.longitude);
        if (d < 12.0) continue;
      }
      final afterBearing = bearings[i + 1];
      final afterDir = _bearingToCompass(afterBearing);
      final turnDir = diff > 0 ? 'Turn right' : 'Turn left';
      out.add(Maneuver(point: point, instruction: '$turnDir, head $afterDir'));
      lastAddedPoint = point;
    }
  }
  out.add(Maneuver(point: route.last, instruction: 'You have arrived'));
  return out;
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
  List<Maneuver> _maneuvers = [];
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
    // move map to start (zoomed-in for walking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(start, 19.0);
    });
    // compute simple maneuvers
    _maneuvers = computeManeuvers(_route);
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
          _mapController.move(p, 19.0);
        } catch (_) {}
      _updateNextManeuver(p);
      setState(() {});
      _stepIndex++;
    });
  }

  void _updateNextManeuver(ll.LatLng p) {
    for (var m in _maneuvers) {
      if (!m.passed) {
        final d = distanceMeters(p.latitude, p.longitude, m.point.latitude, m.point.longitude);
        if (d <= 12.0) m.passed = true;
        else break;
      }
    }
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
        options: MapOptions(center: start, zoom: 19.0, maxZoom: 20.0, minZoom: 14.0),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: ['a','b','c']),
          // split route into passed and remaining based on _stepIndex
          PolylineLayer(polylines: [
            if (_stepIndex > 0) Polyline(points: _route.sublist(0, math.min(_stepIndex, _route.length)), color: Colors.grey.shade500, strokeWidth: 4.0),
            if (_stepIndex < _route.length) Polyline(points: _route.sublist(math.min(_stepIndex, _route.length)), color: Colors.blue, strokeWidth: 4.0),
          ]),
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
      bottomNavigationBar: _buildManeuverBar(),
    );
  }

  Widget _buildManeuverBar() {
    if (_maneuvers.isEmpty) return SizedBox.shrink();
    final cur = LocationService.instance.position.value;
    if (cur == Offset.zero) return SizedBox.shrink();
    final curLatLng = ll.LatLng(cur.dx, cur.dy);
    final nextIndex = _maneuvers.indexWhere((m) => !m.passed);
    final next = nextIndex >= 0 ? _maneuvers[nextIndex] : _maneuvers.last;
    final second = (nextIndex >= 0 && nextIndex + 1 < _maneuvers.length) ? _maneuvers[nextIndex + 1] : null;
    final d = distanceMeters(curLatLng.latitude, curLatLng.longitude, next.point.latitude, next.point.longitude);
    return Container(
      color: Colors.black87,
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.navigation, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(next.instruction, style: TextStyle(color: Colors.white, fontSize: 16)),
                if (second != null) SizedBox(height: 6),
                if (second != null) Text('Then: ${second.instruction}', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text('${d.toStringAsFixed(0)} m', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

}

