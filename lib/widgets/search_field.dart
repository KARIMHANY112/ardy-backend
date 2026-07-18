import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// The pill search bar in the Home Feed header.
class ArdiSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const ArdiSearchField({super.key, required this.controller, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r14)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
          prefixIcon: Icon(Icons.search, color: AppColors.inkAlpha(0.6), size: 20),
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.r14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.r14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.r14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
