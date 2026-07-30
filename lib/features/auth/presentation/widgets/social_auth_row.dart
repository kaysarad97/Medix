import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Блок «или авторизоваться через» с иконками сторонних провайдеров.
///
/// В макете логина провайдер один — Google, иконка 24×24 по центру.
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({super.key, this.onGooglePressed});

  final VoidCallback? onGooglePressed;

  static const double _iconSize = 24;

  /// Область нажатия шире иконки — 24 px мало для пальца.
  static const double _tapTarget = 48;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('или авторизоваться через', style: AppTypography.caption),
        const SizedBox(height: 10),
        SizedBox(
          width: _tapTarget,
          height: _iconSize + 8,
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.allSm,
            child: InkWell(
              onTap: onGooglePressed,
              borderRadius: AppRadius.allSm,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/google.svg',
                  width: _iconSize,
                  height: _iconSize,
                  semanticsLabel: 'Войти через Google',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
