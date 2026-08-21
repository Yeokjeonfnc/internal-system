import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/accessibility/font_scale_provider.dart';

class AppTextScaleShell extends StatefulWidget {
  const AppTextScaleShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppTextScaleShell> createState() => _AppTextScaleShellState();
}

class _AppTextScaleShellState extends State<AppTextScaleShell> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => _AppTextScaleBody(child: widget.child),
  );

  @override
  void didUpdateWidget(covariant AppTextScaleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.child, widget.child)) {
      _entry.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}

class _AppTextScaleBody extends StatelessWidget {
  const _AppTextScaleBody({required this.child});

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
      message: 'Ctrl + 마우스 휠로 글자 크기 조절',
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
