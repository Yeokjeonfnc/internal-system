import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

class ErpDialogFrame extends StatelessWidget {
  const ErpDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 720,
    this.maxHeight,
    this.onClose,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: Material(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErpDialogHeader(
              title: title,
              onClose: onClose ?? () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class ErpDialogHeader extends StatelessWidget {
  const ErpDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.accentRed),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 22),
              color: Colors.white,
              tooltip: '닫기',
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
                hoverColor: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
