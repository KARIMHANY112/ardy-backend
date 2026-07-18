import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// Full-width filled nile-green button — "Publish Listing", "Sign Up", "Log In".
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.nileGreen, borderRadius: BorderRadius.circular(AppRadii.r14)),
        child: loading
            ? const SizedBox(width: AppSpacing.s20, height: AppSpacing.s20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: AppFonts.tajawal(size: 15, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
