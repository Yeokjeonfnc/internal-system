import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/accessibility/font_scale_provider.dart';

class AppTextScaleShell extends StatelessWidget {
  const AppTextScaleShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = provider.Provider.of<FontScaleProvider>(context);
    final media = MediaQuery.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (signal) {
        if (signal is! PointerScrollEvent) return;
        if (!HardwareKeyboard.instance.isControlPressed) return;
        if (signal.scrollDelta.dy < 0) {
          settings.increase();
        } else if (signal.scrollDelta.dy > 0) {
          settings.decrease();
        }
      },
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(settings.scale)),
        child: Stack(
          children: [
            child,
            Positioned(
              right: 14,
              bottom: 14,
              child: _FontScaleBadge(settings: settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontScaleBadge extends StatelessWidget {
  const _FontScaleBadge({required this.settings});

  final FontScaleProvider settings;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Tooltip(
      message:
          'Ctrl + \uB9C8\uC6B0\uC2A4 \uD720\uC744\uB85C \uAE00\uC790 \uD06C\uAE30 \uC870\uC808',
      child: InkWell(
        onTap: settings.reset,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'A ${settings.percentage}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    ),
  );
}
