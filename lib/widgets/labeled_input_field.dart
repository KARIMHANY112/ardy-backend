import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// A label above a sandy rounded field — the input style used on Sign Up,
/// Log In, and Post Listing.
class LabeledInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? suffixText;
  final bool obscureText;
  final TextInputType? keyboardType;

  const LabeledInputField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.suffixText,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.inkAlpha(0.6))),
        const SizedBox(height: AppSpacing.s6),
        Container(
          height: 46,
          decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r12)),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
              suffixText: suffixText,
              suffixStyle: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.r12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.r12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.r12), borderSide: const BorderSide(color: AppColors.nileGreen, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}
