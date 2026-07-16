import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

/// One of the 3 square photo-attach slots on Post Listing. Tapping opens the
/// gallery picker; a picked photo replaces the placeholder icon.
///
/// Holds an [XFile] rather than `dart:io File` so this also works on the
/// web target — `File` can't be constructed from a blob: path there.
class PhotoUploadSlot extends StatelessWidget {
  final XFile? image;
  final ValueChanged<XFile> onPicked;

  const PhotoUploadSlot({super.key, required this.image, required this.onPicked});

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        width: 88,
        height: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.sandy,
          borderRadius: BorderRadius.circular(12),
          border: image == null ? Border.all(color: AppColors.divider) : null,
        ),
        child: image == null
            ? const Icon(Icons.add_a_photo_outlined, color: AppColors.divider)
            : (kIsWeb ? Image.network(image!.path, fit: BoxFit.cover) : Image.file(File(image!.path), fit: BoxFit.cover)),
      ),
    );
  }
}
