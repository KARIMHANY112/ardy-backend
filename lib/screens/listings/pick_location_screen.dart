import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_theme.dart';

/// Full-screen map picker — tap anywhere to drop a pin, then confirm.
/// Pushed with Navigator (not go_router) since it's a transient modal step,
/// and pops back with the picked LatLng (or null if cancelled).
class PickLocationScreen extends StatefulWidget {
  final LatLng? initial;

  const PickLocationScreen({super.key, this.initial});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  // Cairo — reasonable default center when the submitter hasn't picked before.
  static const _defaultCenter = LatLng(30.0444, 31.2357);

  late LatLng _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial ?? _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: Colors.white,
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_picked),
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _picked, zoom: 12),
        onTap: (latLng) => setState(() => _picked = latLng),
        markers: {
          Marker(markerId: const MarkerId('picked'), position: _picked),
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Tap anywhere on the map to drop the pin, then tap Confirm',
            textAlign: TextAlign.center,
            style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
          ),
        ),
      ),
    );
  }
}
