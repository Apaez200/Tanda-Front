import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum CustomButtonVariant { primary, secondary, danger, disabled }

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final bool loading;
  final bool fullWidth;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  double _scale = 1;

  void _setPressed(bool v) {
    setState(() => _scale = v ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.variant == CustomButtonVariant.disabled || widget.loading;
    final colors = _colorsFor(widget.variant, disabled);

    final child = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: colors.bg,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: disabled ? null : widget.onPressed,
          onHighlightChanged: disabled ? null : _setPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            alignment: Alignment.center,
            child: widget.loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.fg,
                    ),
                  )
                : Text(
                    widget.label,
                    style: dmSans(16, color: colors.fg, weight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }

  _BtnColors _colorsFor(CustomButtonVariant v, bool disabled) {
    if (disabled && widget.variant != CustomButtonVariant.disabled) {
      return _BtnColors(softGray.withOpacity(0.35), softGray);
    }
    switch (v) {
      case CustomButtonVariant.primary:
        return _BtnColors(accentGold, darkBg);
      case CustomButtonVariant.secondary:
        return _BtnColors(primaryGreen, offWhite);
      case CustomButtonVariant.danger:
        return _BtnColors(warningRed, offWhite);
      case CustomButtonVariant.disabled:
        return _BtnColors(softGray.withOpacity(0.35), softGray);
    }
  }
}

class _BtnColors {
  const _BtnColors(this.bg, this.fg);
  final Color bg;
  final Color fg;
}
