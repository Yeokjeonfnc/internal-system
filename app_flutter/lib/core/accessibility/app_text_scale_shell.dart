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
            // 배지는 Positioned 만 쓴다. 예전에는 Tooltip 조상용으로 자체 Overlay 를
            // 올렸는데, 그 `_RenderTheater` 가 웹에서 뷰 포커스 전환 때 아직
            // 레이아웃되지 않은 채로 focus traversal 에 잡혀 assert 가 터졌다.
            // (iframe 본문 ↔ Flutter 다이얼로그 전환에서 재현.)
            Positioned(
              right: 14,
              bottom: 14,
              child: ExcludeFocus(
                child: _FontScaleBadge(settings: settings),
              ),
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
    child: Semantics(
      button: true,
      label: 'Ctrl + 마우스 휠로 글자 크기 조절. 누르면 기본 크기로.',
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
