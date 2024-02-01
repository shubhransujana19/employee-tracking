import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();

}

class _MapViewState extends State<MapView> {

  String? userName = FirebaseAuth.instance.currentUser?.displayName;

  GoogleMapController? _mapController;
  Position? _currentLocation;
  final List<LatLng> _routeCoordinates = [];
  Timer? trackingInterval;
  double _totalDistance = 0;
  String? _locationName;
  String? text;
  @override
  void initState() {
    super.initState();     
    _checkLocationPermissions();   
 }

// @override
//   void dispose() {
//    _stopTracking();
//     super.dispose();
//   }

  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.deniedForever) {
        // Show a dialog explaining the need for location permission
        _showPermissionDeniedDialog();
      } else if (permission == LocationPermission.denied) {
        // Request location permission again
        _showPermissionRequestDialog();
      } else {
        // Permissions granted, proceed with location-based features
        _startLocationUpdates();
      }
    } else {
      // Permissions already granted, proceed with location-based features
      _startLocationUpdates();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  const Text("Location Permission Denied"),
          content: const  Text("Please grant location permission to use this app."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const  Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text("This app requires location permission to function."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkLocationPermissions(); // Request permission again
              },
              child: const Text("Grant"),
            ),
          ],
        );
      },
    );
  }

  void _startLocationUpdates() {
    // Your existing code to start location updates
    // For example, you can call _startTracking() here
    _startTracking();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(     
        body: Column(
              children: [
                // Location Name Display
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Colors.black87],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          _locationName ?? 'Loading...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                ),
              ),
            
            
              Expanded(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _currentLocation != null
                      ? CameraPosition(
                          target: LatLng(
                            _currentLocation!.latitude,
                            _currentLocation!.longitude,
                          ),
                          zoom: 15, // Set your desired zoom level here
                        )
                      : const CameraPosition(
                          target: LatLng(0, 0),
                          zoom: 15,
                        ),
                        mapType: MapType.hybrid,
                  markers: Set<Marker>.from(_createMarkers()),
                  polylines: Set<Polyline>.from(_createPolylines()),
                  myLocationEnabled: true, // Show user's location on the map
                ),
              ),
              
                      
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Start/Stop Tracking Buttons                        
                            ElevatedButton(
                              onPressed: () async{
                                final service = FlutterBackgroundService();
                                bool isRunning = await service.isRunning();
                                if (isRunning) {
                                  service.invoke('stopTracking');                              
                                }else{
                                  service.startService();
                                }
                                if(!isRunning){
                                 text = "Stop Tracking";
                                }else{
                                 text = "Start Tracking";
                                }
                                setState(() {
                                  
                                });
                                
                                if (trackingInterval != null) {
                                  _stopTracking();
                                } else {
                                  _startTracking();
            
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.green[900], backgroundColor: trackingInterval != null ? Colors.red : Colors.lightGreen[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(trackingInterval != null ? Icons.stop : Icons.play_arrow),
                                  const SizedBox(width: 5),
                                  Text(trackingInterval != null ? 'Stop' : 'Start', style: const TextStyle(fontSize: 20.0)),
                                ],
                              ),
                            ),
                              
                          const SizedBox(width: 20,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  trackingInterval != null ? Icons.circle : Icons.circle_outlined,
                                  color: trackingInterval != null ? Colors.green : Colors.red,
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                const Text('Tracking'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20), // Add vertical spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
                              style: TextStyle(
                                fontSize: 18, // Increase font size for better visibility
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ]
                        )
                      ],
                    ),
                  ),
              ]
            ),
    
    );
  }

  void _onMapCreated(GoogleMapController controller) {
      _mapController = controller;
    }

  Set<Marker> _createMarkers() {
      if (_currentLocation == null) {
        return {};
      }
      return {
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          // ... other marker options
        ),
      };
    }

  Iterable<Polyline> _createPolylines() {
    if (_routeCoordinates.length > 1) {
      return [
        Polyline(
          polylineId: const PolylineId('trackingRoute'),
          points: _routeCoordinates,
          color: Colors.blue,
          width: 5,
        ),
      ];
    } else {
      return []; // Return an empty iterable if there are no route coordinates
    }
  }


  void _startTracking() async {
    // Check for permissions (not shown here)

    // Get initial location
    _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _updateMap(_currentLocation!);

    // Start periodic updates
    trackingInterval = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        _updateLocation();
        _sendDataToServer(action: 'stop', status: 'inactive'); // Send data to server on each update
      },
    );


    setState(() {}); // Trigger UI update to show/hide the polylines
  }

     
  void _stopTracking() {
    trackingInterval?.cancel();
    trackingInterval = null;
    // ... other cleanup tasks (e.g., reset UI elements)
    // Send data to the server with action stop and status inactive
  _sendDataToServer(action: 'stop', status: 'inactive');


    setState(() {}); // Trigger UI update to show/hide the polylines

  }

void _updateLocation() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi) {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Use Geocoding API to get the location name
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyBzobceEDK5s37lC312jOO16O1_sBUrGyc'));

      if (response.statusCode == 200) {
        // Parse the response and extract the location name
        final decoded = json.decode(response.body);
        String locationName = decoded['results'][0]['formatted_address'];

        // Update the UI with the location name
        setState(() {
          _currentLocation = position;
          _routeCoordinates.add(LatLng(position.latitude, position.longitude));
          _locationName = locationName; // Add this to your state variables

          if (_currentLocation != null && _routeCoordinates.isNotEmpty){
            double distance = Geolocator.distanceBetween(
              _routeCoordinates.last.latitude,
               _routeCoordinates.last.longitude,
                _currentLocation!.latitude,
                 _currentLocation!.longitude,
              );

              _totalDistance += distance;
          }
        });
      }
    } catch (error) {
      // Handle errors
    }
  } else {
    // Handle offline scenario
    debugPrint('Cannot update location: offline');
  }
}


void _updateMap(Position position) {
  setState(() {
    _currentLocation = position;
    // Add new coordinate to route
    _routeCoordinates.add(LatLng(position.latitude, position.longitude));
  });
  }

String formatDateTime(String inputDateTime) {
  DateTime dateTime = DateTime.parse(inputDateTime);
  String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  return formattedDateTime;
}



void _sendDataToServer({required String action, required String status}) async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi) {
    try {
      final currentTime = formatDateTime(DateTime.now().toIso8601String());


      final List<Map<String, dynamic>> path = _routeCoordinates.map((coord) {
        return {
          'latitude': coord.latitude,
          'longitude': coord.longitude,
        };
      }).toList();
      final String trackingPathJson = jsonEncode(path);

      final Map<String, dynamic> data = {
        'username': userName,
        'latitude': _currentLocation?.latitude.toDouble() ?? 0.0,
        'longitude': _currentLocation?.longitude.toDouble() ?? 0.0,
        'action': trackingInterval != null ? 'start' : 'stop',
        'status': trackingInterval != null ? 'active' : 'inactive',
        'internetStatus':
            connectivityResult == ConnectivityResult.mobile ||
                    connectivityResult == ConnectivityResult.wifi
                ? 'online'
                : 'offline',
        'locationName': _locationName ?? '',
        'trackingPath': trackingPathJson,
        'distance': _totalDistance ?? 0.0,
        'currentDateAndTime': currentTime,
        // ... other data to send
      };

      // Log the data before sending
      print('Data being sent to server: $data');

      // Send HTTP POST request
      final response = await http.post(
        Uri.parse('https://wmps.in/staff/gps/server.php/'),
        body: jsonEncode(data), // Ensure sending data as JSON
      );

      if (response.statusCode == 200) {
        // Handle successful response
        debugPrint('Data sent to server successfully');
      } else {
        // Handle error response
        debugPrint('Error sending data to server: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network errors
      debugPrint('Error sending data: $error');
    }
  } else {
    // Handle offline scenario
    debugPrint('Cannot send data: offline');
  }
}



}

