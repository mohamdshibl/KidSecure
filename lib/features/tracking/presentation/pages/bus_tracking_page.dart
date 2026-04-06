import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bus_tracking/domain/repositories/bus_tracking_repository.dart';
import '../../../bus_tracking/domain/entities/bus_location.dart';

class BusTrackingPage extends StatefulWidget {
  final String busId;

  const BusTrackingPage({super.key, required this.busId});

  @override
  State<BusTrackingPage> createState() => _BusTrackingPageState();
}

class _BusTrackingPageState extends State<BusTrackingPage> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  bool _mapError = false;
  late final Stream<BusLocationEntity> _busLocationStream;

  @override
  void initState() {
    super.initState();
    _busLocationStream = context.read<BusTrackingRepository>().streamBusLocation(widget.busId);
  }

  @override
  Widget build(BuildContext context) {
    if (_mapError) {
      return _buildMapError();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Live Bus Tracking', style: GoogleFonts.outfit()),
      ),
      body: StreamBuilder<BusLocationEntity>(
        stream: _busLocationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          
          if (data == null || !data.tripActive) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bus is currently offline',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _LoadingText()
                  else
                    Text(
                      'Waiting for driver to start trip...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            );
          }

          final lat = data.latitude;
          final lng = data.longitude;
          final pos = LatLng(lat, lng);

          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId(widget.busId),
              position: pos,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(title: 'Bus: ${widget.busId}'),
            ),
          );
          
          if (_controller != null) {
            _controller!.animateCamera(CameraUpdate.newLatLng(pos));
          }

          return Stack(
            children: [
              _SafeGoogleMap(
                position: pos,
                markers: _markers,
                onMapCreated: (controller) => _controller = controller,
                onError: () {
                  if (mounted) setState(() => _mapError = true);
                },
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.3
                              : 0.1,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Status: Live',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Last updated: Just now',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapError() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Live Bus Tracking', style: GoogleFonts.outfit()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: Colors.orange.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Map Not Available',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Google Maps API key is not configured.\nPlease add a valid API key to use bus tracking.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafeGoogleMap extends StatefulWidget {
  final LatLng position;
  final Set<Marker> markers;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onError;

  const _SafeGoogleMap({
    required this.position,
    required this.markers,
    required this.onMapCreated,
    required this.onError,
  });

  @override
  State<_SafeGoogleMap> createState() => _SafeGoogleMapState();
}

class _SafeGoogleMapState extends State<_SafeGoogleMap> {
  @override
  void initState() {
    super.initState();
    // Catch platform errors that happen during GoogleMap creation
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('API key')) {
        widget.onError();
      } else {
        originalOnError?.call(details);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: widget.position, zoom: 15),
      onMapCreated: widget.onMapCreated,
      markers: widget.markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
    );
  }
}

class _LoadingText extends StatefulWidget {
  const _LoadingText();

  @override
  State<_LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<_LoadingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        'Connecting to live feed...',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }
}
