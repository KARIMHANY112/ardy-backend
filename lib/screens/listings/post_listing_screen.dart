import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/listing.dart';
import '../../services/api_client.dart';
import '../../services/listings_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/labeled_input_field.dart';
import '../../widgets/photo_upload_slot.dart';
import '../../widgets/primary_button.dart';
import 'pick_location_screen.dart';

/// Post Listing (seller form) — direction 1a: nile-green pill selectors,
/// sand-bg inputs, nile "Publish Listing" button. Single page, no wizard.
class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  ListingCategory _category = ListingCategory.factory;
  LicenseStatus _license = LicenseStatus.licensed;
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();
  final List<XFile?> _photos = [null, null, null];
  LatLng? _pickedLocation;
  bool _submitting = false;

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => PickLocationScreen(initial: _pickedLocation)),
    );
    if (result != null) setState(() => _pickedLocation = result);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final area = double.tryParse(_areaController.text.trim());
    final location = _locationController.text.trim();

    if (title.isEmpty || price == null || area == null || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in title, price, area, and location')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<ListingsRepository>();
      final listing = await repo.create(
        title: title,
        category: _category,
        price: price,
        size: area,
        location: location,
        license: _license,
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
      );

      for (final photo in _photos.whereType<XFile>()) {
        final bytes = await photo.readAsBytes();
        await repo.uploadPhoto(listing.id, bytes: bytes, filename: photo.name);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing is now live')),
      );
      setState(() {
        _titleController.clear();
        _priceController.clear();
        _areaController.clear();
        _locationController.clear();
        _photos.setAll(0, [null, null, null]);
        _pickedLocation = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      currentIndex: -1, // no longer a bottom-nav tab; reached via the buyer dashboard card
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandHeader(title: 'Post a Listing', subtitle: 'Reach verified commercial buyers'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s0, AppSpacing.s18, AppSpacing.s18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.inkAlpha(0.6))),
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    children: [
                      for (final category in ListingCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s8),
                          child: CategoryPill(label: category.label, selected: _category == category, onTap: () => setState(() => _category = category)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  LabeledInputField(label: 'Title', controller: _titleController, hint: 'e.g. Industrial Unit, 10th of Ramadan'),
                  const SizedBox(height: AppSpacing.s14),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledInputField(
                          label: 'Price',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          suffixText: 'EGP',
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Expanded(
                        child: LabeledInputField(
                          label: 'Area',
                          controller: _areaController,
                          keyboardType: TextInputType.number,
                          suffixText: 'sqm',
                          hint: '0',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  LabeledInputField(label: 'Location', controller: _locationController, hint: 'City, area'),
                  const SizedBox(height: AppSpacing.s10),
                  GestureDetector(
                    onTap: _pickLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
                      decoration: BoxDecoration(
                        color: AppColors.sandy,
                        borderRadius: BorderRadius.circular(AppRadii.r12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pickedLocation == null ? Icons.add_location_alt_outlined : Icons.check_circle,
                            color: _pickedLocation == null ? AppColors.inkAlpha(0.6) : AppColors.nileGreen,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.s10),
                          Expanded(
                            child: Text(
                              _pickedLocation == null
                                  ? 'Add map pin (optional)'
                                  : 'Pin set — ${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}',
                              style: AppFonts.tajawal(size: 13, weight: FontWeight.w600, color: AppColors.ink),
                            ),
                          ),
                          Text(
                            _pickedLocation == null ? 'Pick' : 'Change',
                            style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  Text('Licensing status', style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.inkAlpha(0.6))),
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    children: [
                      for (final status in LicenseStatus.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s8),
                          child: CategoryPill(label: status.label, selected: _license == status, onTap: () => setState(() => _license = status)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  Text('Photos', style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.inkAlpha(0.6))),
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    children: [
                      for (var i = 0; i < _photos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s10),
                          child: PhotoUploadSlot(
                            image: _photos[i],
                            onPicked: (file) => setState(() => _photos[i] = file),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  PrimaryButton(label: 'Publish Listing', onPressed: _publish, loading: _submitting),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
