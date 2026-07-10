import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  ListingCategory _category = ListingCategory.land;
  LicenseStatus _license = LicenseStatus.pending;
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _publish() {
    // Stub: POST /listings isn't wired up yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing submitted for review (not wired up yet)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBottomNavScaffold(
      currentIndex: 3,
      title: 'Post Listing',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ListingCategory.values
                  .map((category) => ChoiceChip(
                        label: Text(category.label),
                        selected: _category == category,
                        selectedColor: AppColors.nileGreen,
                        labelStyle: TextStyle(color: _category == category ? Colors.white : AppColors.ink),
                        onSelected: (_) => setState(() => _category = category),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (EGP)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Area (sqm)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 16),
            Text('Licensing Status', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: LicenseStatus.values
                  .map((status) => ChoiceChip(
                        label: Text(status.label),
                        selected: _license == status,
                        selectedColor: AppColors.nileGreen,
                        labelStyle: TextStyle(color: _license == status ? Colors.white : AppColors.ink),
                        onSelected: (_) => setState(() => _license = status),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Photos', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.sandy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _publish, child: const Text('Publish Listing')),
          ],
        ),
      ),
    );
  }
}
