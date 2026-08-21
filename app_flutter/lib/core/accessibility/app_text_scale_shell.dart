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
            // 배지를 자체 Overlay 안에 넣는다.
            //
            // 이 위젯은 MaterialApp.builder 로 붙으므로 **라우터가 만드는
            // Navigator(=Overlay) 보다 위**에 있다. 그래서 여기 놓인 Tooltip 은
            // Overlay 조상을 찾지 못해 build 마다 예외를 던졌다.
            // 릴리즈 빌드에서 그 예외는 ErrorWidget = **회색 사각형**으로 그려지고,
            // 디버그에서는 탭 처리까지 함께 죽어 로그인 버튼이 먹통이 됐다.
            //
            // 화면 전체 크기의 Overlay 지만 항목이 우하단 Positioned 하나뿐이라
            // 그 밖의 영역은 히트테스트에 걸리지 않는다 — 아래 화면 조작을 막지 않는다.
            Positioned.fill(
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => Positioned(
                      right: 14,
                      bottom: 14,
                      child: _FontScaleBadge(settings: settings),
                    ),
                  ),
                ],
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
    child: Tooltip(
      message: 'Ctrl + \uB9C8\uC6B0\uC2A4 \uD720\uB85C \uAE00\uC790 \uD06C\uAE30 \uC870\uC808',
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
