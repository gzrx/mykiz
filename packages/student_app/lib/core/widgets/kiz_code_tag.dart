import 'package:flutter/material.dart';
import '../theme/kiz_theme.dart';

/// A small tag for anything that is literally a code — a booking reference,
/// an application UUID, a room/block/bed identifier. Styled like a physical
/// door-number plate: mono type, cork-tinted background, tight radius.
class KizCodeTag extends StatelessWidget {
  const KizCodeTag(this.code, {super.key, this.fontSize = 12});

  final String code;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: KizColors.cork.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: KizFonts.mono(
          fontSize: fontSize,
          color: KizColors.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
