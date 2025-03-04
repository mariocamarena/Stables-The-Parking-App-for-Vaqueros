import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/secret.dart';


class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  final LatLng _initialPosition = const LatLng(26.303328, -98.170846);

  @override
  Widget build(BuildContext context) {
    
    const double squareSize = 500.0; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("INSERT LOT NAME Map"),
      ),
      body: Center(
        child: SizedBox(
          width: squareSize,
          height: squareSize,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 19.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken':
                      Config.mapboxToken,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
