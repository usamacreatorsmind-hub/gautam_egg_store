import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class SelectAddressOnMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const SelectAddressOnMapScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<SelectAddressOnMapScreen> createState() =>
      _SelectAddressOnMapScreenState();
}

class _SelectAddressOnMapScreenState extends State<SelectAddressOnMapScreen> {
  GoogleMapController? _mapController;

  LatLng? _pinnedLatLng;
  LatLng? _cameraCenter;

  String _selectedAddress = 'Move the map to position the pin';
  geocoding.Placemark? _selectedPlacemark;
  bool _loadingAddress = false;
  bool _cameraMoving = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;

  static const LatLng _indiaCenter = LatLng(20.5937, 78.9629);

  LatLng get _initialTarget =>
      widget.initialLatitude != null && widget.initialLongitude != null
          ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
          : _indiaCenter;

  double get _initialZoom => widget.initialLatitude != null ? 16.0 : 5.0;

  @override
  void initState() {
    super.initState();
    _cameraCenter = _initialTarget;
    _pinnedLatLng = widget.initialLatitude != null ? _initialTarget : null;
    if (widget.initialLatitude == null) {
      _gotoCurrentLocation();
    }
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _gotoCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    } catch (_) {}
  }

  // ── Camera callbacks ───────────────────────────────────────────────────────

  void _onCameraMove(CameraPosition pos) {
    _cameraCenter = pos.target;
    if (!_cameraMoving) setState(() => _cameraMoving = true);
  }

  Future<void> _onCameraIdle() async {
    final center = _cameraCenter;
    if (center == null) return;
    setState(() {
      _cameraMoving = false;
      _pinnedLatLng = center;
      _loadingAddress = true;
    });
    await _reverseGeocode(center);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final parts = [
        placemark?.street,
        placemark?.subLocality,
        placemark?.locality,
        placemark?.administrativeArea,
        placemark?.postalCode,
      ].where((p) => p != null && p.trim().isNotEmpty).cast<String>();

      if (!mounted) return;
      setState(() {
        _selectedPlacemark = placemark;
        _selectedAddress =
            parts.isEmpty ? 'Selected location' : parts.join(', ');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedPlacemark = null;
        _selectedAddress = 'Unable to resolve address';
      });
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  // ── Search (free — device OS geocoder, no API key) ─────────────────────────

  Future<void> _searchAddress(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    _searchFocus.unfocus();
    setState(() => _searching = true);
    try {
      final locations = await geocoding.locationFromAddress(query);
      if (!mounted || locations.isEmpty) return;
      final loc = locations.first;
      final latLng = LatLng(loc.latitude, loc.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    } catch (_) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Location not found. Try a different address.',
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  void _confirmLocation() {
    if (_pinnedLatLng == null) return;
    Navigator.pop(context, {
      'latitude': _pinnedLatLng!.latitude,
      'longitude': _pinnedLatLng!.longitude,
      'address': _selectedAddress,
      'placemark': _selectedPlacemark,
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Delivery Location')),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchAddress,
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: AppLoader(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: scheme.surface,
              ),
            ),
          ),

          // ── Map + center pin overlay ──────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialTarget,
                    zoom: _initialZoom,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (c) => _mapController = c,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  onTap: (latLng) {
                    _searchFocus.unfocus();
                    _mapController
                        ?.animateCamera(CameraUpdate.newLatLng(latLng));
                  },
                ),

                // Fixed center pin
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(
                            0, _cameraMoving ? -12 : 0, 0),
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: scheme.primary,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _cameraMoving ? 10 : 6,
                        height: _cameraMoving ? 4 : 3,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text('Delivery location',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                _loadingAddress || _cameraMoving
                    ? Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: AppLoader(
                                strokeWidth: 2, color: scheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Text('Locating address...',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      )
                    : Text(
                        _selectedAddress,
                        style: TextStyle(fontSize: 14, color: scheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                if (_pinnedLatLng != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_pinnedLatLng!.latitude.toStringAsFixed(5)}, '
                    '${_pinnedLatLng!.longitude.toStringAsFixed(5)}',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_pinnedLatLng == null ||
                            _cameraMoving ||
                            _loadingAddress)
                        ? null
                        : _confirmLocation,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Confirm Location',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
