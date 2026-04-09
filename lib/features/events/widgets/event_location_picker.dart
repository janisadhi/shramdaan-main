import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/utils/location_utils.dart';

class EventLocationData {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  const EventLocationData({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

class EventLocationPicker extends StatefulWidget {
  final EventLocationData? initialValue;
  final ValueChanged<EventLocationData> onChanged;

  const EventLocationPicker({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<EventLocationPicker> createState() => _EventLocationPickerState();
}

class _EventLocationPickerState extends State<EventLocationPicker> {
  late final MapController _mapController;
  late final TextEditingController _searchController;
  late LatLng _selectedPoint;
  Timer? _debounce;
  bool _isResolvingAddress = false;
  List<LocationSearchResult> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final cachedPosition = LocationUtils.cachedPosition;
    _selectedPoint = LatLng(
      widget.initialValue?.latitude ??
          cachedPosition?.latitude ??
          LocationUtils.fallbackLatitude,
      widget.initialValue?.longitude ??
          cachedPosition?.longitude ??
          LocationUtils.fallbackLongitude,
    );
    _searchController = TextEditingController(
      text: widget.initialValue?.formattedAddress ?? '',
    );

    if (widget.initialValue == null && cachedPosition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bootstrapCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapCurrentLocation() async {
    final position = await LocationUtils.prewarmCurrentPosition();
    if (!mounted || position == null) return;
    await _setPoint(
      LatLng(position.latitude, position.longitude),
      addressOverride: _searchController.text.trim().isEmpty
          ? 'Current location'
          : _searchController.text.trim(),
    );
  }

  Future<void> _setPoint(LatLng point, {String? addressOverride}) async {
    setState(() {
      _selectedPoint = point;
      _isResolvingAddress = true;
    });

    var formattedAddress = addressOverride ?? '';
    if (formattedAddress.isEmpty || formattedAddress == 'Current location') {
      formattedAddress =
          await LocationUtils.reverseGeocode(
            latitude: point.latitude,
            longitude: point.longitude,
          ) ??
          formattedAddress;
    }

    if (formattedAddress.isEmpty) {
      formattedAddress =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }

    _searchController.text = formattedAddress;
    widget.onChanged(
      EventLocationData(
        latitude: point.latitude,
        longitude: point.longitude,
        formattedAddress: formattedAddress,
      ),
    );

    if (!mounted) return;
    setState(() {
      _suggestions = const [];
      _isResolvingAddress = false;
    });
    _mapController.move(point, _mapController.camera.zoom);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = value.trim();
      if (query.length < 3) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _isResolvingAddress = false;
        });
        return;
      }

      setState(() => _isResolvingAddress = true);
      try {
        final results = await LocationUtils.searchAddresses(query, limit: 5);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _isResolvingAddress = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _isResolvingAddress = false;
        });
      }
    });
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isResolvingAddress = true);
    try {
      final results = await LocationUtils.searchAddresses(query, limit: 5);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isResolvingAddress = false;
      });
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find that address.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isResolvingAddress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find that address.')),
      );
    }
  }

  Future<void> _selectSuggestion(LocationSearchResult result) async {
    FocusScope.of(context).unfocus();
    await _setPoint(
      LatLng(result.latitude, result.longitude),
      addressOverride: result.label,
    );
  }

  Future<void> _useMyLocation() async {
    setState(() => _isResolvingAddress = true);
    try {
      final position = await LocationUtils.prewarmCurrentPosition();
      if (position == null) {
        throw Exception('No device location');
      }

      await _setPoint(LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isResolvingAddress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location unavailable. Check GPS and permissions.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Search Address',
                  hintText: 'Search or drop a pin on the map',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  suffixIcon: _isResolvingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchAddress,
                        ),
                ),
                onChanged: _onSearchChanged,
                onFieldSubmitted: (_) => _searchAddress(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _isResolvingAddress ? null : _useMyLocation,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: const Color(0xFFEAF4FF),
                foregroundColor: const Color(0xFF005EB8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.near_me_rounded, size: 18),
              label: const Text('Use Mine'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      suggestion.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 14,
                onTap: (_, point) => _setPoint(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.myapp',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Type at least 3 characters to see suggestions, then tap the correct place.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
