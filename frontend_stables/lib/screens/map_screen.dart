import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final LatLng _initialPosition = LatLng(26.3082, -98.1740); // UTRGV

// added 2 new lots on campus
  final Map<String, LatLng> lotPositions = {
    'Lot 1': LatLng(26.3082, -98.1740),  
    'Lot 2': LatLng(26.308624, -98.17235),  
    'Lot 3': LatLng(26.308805, -98.17437),  
  };

// set to lot one as it already was by mario
String selectedLot = 'Lot 1';

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

  void _updateLot(String lot) {
    LatLng lotPosition = lotPositions[lot]!;
    _controller?.animateCamera(CameraUpdate.newLatLng(lotPosition));
    setState(() {
      selectedLot = lot; // updates the lot if selected
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vaquero Map",style: TextStyle(color: Color.fromARGB(255, 254, 253, 253))),
        actions: [
          Padding( // Add padding to the dropdown button to give space
            padding: const EdgeInsets.only(right: 10.0, top: 10.0), // spacing
            child: DropdownButton<String>(
              value: selectedLot,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _updateLot(newValue); // chnages lot here if needed
                }
              },
              items: lotPositions.keys.map<DropdownMenuItem<String>>((String lot) {
                return DropdownMenuItem<String>(
                  value: lot,
                  child: Text(lot, style: const TextStyle(color: Color(0xFFFF8200))),
                );
              }).toList(),
              // fix dropdown menu prob
              dropdownColor: Colors.white,
              iconSize: 30, 
              elevation: 5,
            ),
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 15.0, 
        ),
      ),
    );
  }
}

