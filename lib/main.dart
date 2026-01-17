import 'package:flutter/material.dart';


void main() => runApp(WalkingTourApp());


class WalkingTourApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walking Tour',
      home: TourListScreen(),
    );
  }
}

class TourListScreen extends StatelessWidget {
  final List<Tour> tours = [
    Tour(
      name: 'City Highlights',
      waypoints: [
        Waypoint(
          name: 'Central Park',
          info: 'A beautiful park in the city center.',
          audioUrl: '',
        ),
        Waypoint(
          name: 'Museum',
          info: 'Explore the city museum.',
          audioUrl: '',
        ),
      ],
    ),
    Tour(
      name: 'Historic Walk',
      waypoints: [
        Waypoint(
          name: 'Old Town Square',
          info: 'Historic heart of the city.',
          audioUrl: '',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Walking Tours')),
      body: ListView.builder(
        itemCount: tours.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tours[index].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaypointListScreen(tour: tours[index]),
                ),
              );
            },
          );
        },
      ),
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
            subtitle: Text(waypoint.info),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaypointDetailScreen(waypoint: waypoint),
                ),
              );
            },
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
  Waypoint({required this.name, required this.info, required this.audioUrl});
}
