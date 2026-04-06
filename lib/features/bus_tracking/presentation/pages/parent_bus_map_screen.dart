import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../cubit/bus_tracking_cubit.dart';
import '../cubit/bus_tracking_state.dart';

class ParentBusMapScreen extends StatefulWidget {
  final String busId;

  const ParentBusMapScreen({super.key, required this.busId});

  @override
  State<ParentBusMapScreen> createState() => _ParentBusMapScreenState();
}

class _ParentBusMapScreenState extends State<ParentBusMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Subscribe to Firebase Realtime stream from Cubit
    context.read<BusTrackingCubit>().subscribeToBus(widget.busId);
  }

  @override
  void deactivate() {
    context.read<BusTrackingCubit>().unsubscribe();
    super.deactivate();
  }

  void _updateMarker(double lat, double lng) {
    var markerId = const MarkerId('bus_marker');
    var newPosition = LatLng(lat, lng);
    
    var marker = Marker(
      markerId: markerId,
      position: newPosition,
      infoWindow: const InfoWindow(title: 'School Bus'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    setState(() {
      _markers[markerId] = marker;
    });

    _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLng(newPosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
      ),
      body: BlocConsumer<BusTrackingCubit, BusTrackingState>(
        listener: (context, state) {
          if (state is BusTrackingLoaded) {
            _updateMarker(state.location.latitude, state.location.longitude);
          } else if (state is BusTripEnded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The bus has reached its destination. Trip ended.'),
                backgroundColor: Colors.amber,
              ),
            );
          } else if (state is BusTrackingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BusTrackingLoading || state is BusTrackingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BusTrackingError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          LatLng initialLocation = const LatLng(0, 0); // fallback

          if (state is BusTrackingLoaded) {
            initialLocation = LatLng(state.location.latitude, state.location.longitude);
          }

          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: initialLocation,
              zoom: 16.5,
            ),
            markers: _markers.values.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          );
        },
      ),
    );
  }
}
