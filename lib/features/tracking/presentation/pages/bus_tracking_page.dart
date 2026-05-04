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
  bool _mapError = false;
  late Stream<BusLocationEntity> _busLocationStream;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing BusTrackingPage for busId: ${widget.busId}');
    _busLocationStream = context.read<BusTrackingRepository>().streamBusLocation(widget.busId);
  }

  @override
  void didUpdateWidget(BusTrackingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busId != widget.busId) {
      debugPrint('BusId changed from ${oldWidget.busId} to ${widget.busId}, updating stream.');
      setState(() {
        _busLocationStream = context.read<BusTrackingRepository>().streamBusLocation(widget.busId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mapError) {
      return _buildMapError();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Live Bus Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<BusLocationEntity>(
        stream: _busLocationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          
          if (snapshot.connectionState == ConnectionState.waiting && data == null) {
            return _buildOfflineView(
              context, 
              isConnecting: true,
            );
          }

          if (data == null || !data.tripActive) {
            return _buildOfflineView(
              context, 
              isConnecting: false,
            );
          }

          final lat = data.latitude;
          final lng = data.longitude;
          final pos = LatLng(lat, lng);

          final currentMarkers = <Marker>{
            Marker(
              markerId: MarkerId(widget.busId),
              position: pos,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(title: 'Bus: ${widget.busId}'),
            ),
          };
          
          if (_controller != null) {
            Future.microtask(() {
              if (mounted) {
                _controller?.animateCamera(CameraUpdate.newLatLng(pos));
              }
            });
          }

          return Stack(
            children: [
              _SafeGoogleMap(
                position: pos,
                markers: currentMarkers,
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

  Widget _buildOfflineView(BuildContext context, {required bool isConnecting}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PulsingBusIcon(),
            const SizedBox(height: 32),
            Text(
              'Bus is currently offline',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (isConnecting)
              const _LoadingText()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Waiting for the driver to start the scheduled trip. You\'ll see the live location here once they begin.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 48),
            if (!isConnecting)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    // Trigger a rebuild to re-initialize the stream
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
          ],
        ),
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

class _PulsingBusIcon extends StatefulWidget {
  @override
  State<_PulsingBusIcon> createState() => _PulsingBusIconState();
}

class _PulsingBusIconState extends State<_PulsingBusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.directions_bus_rounded,
          size: 80,
          color: Theme.of(context).primaryColor.withOpacity(0.6),
        ),
      ),
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
