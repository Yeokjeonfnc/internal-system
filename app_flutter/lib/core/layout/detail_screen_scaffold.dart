// 상세 화면 공통 스캐폴드(타이틀·탭·본문).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 상세 화면 제목 줄 아래 보조 문구 색 (이름 옆 톤 다운).
const Color kDetailHeadlineMuted = Color(0xFF50555E);

/// ERP 상세 화면 상단 **한 줄 제목** (이름 + 접미 / 또는 단일 문구).
///
/// 패딩·폰트는 가맹점·창업자·물건 상세에서 동일하게 사용한다.
class DetailScreenHeadline extends StatelessWidget {
  const DetailScreenHeadline._({super.key, required this.child});

  final Widget child;

  static const EdgeInsets headlinePadding = EdgeInsets.fromLTRB(16, 14, 16, 10);

  /// 굵은 [lead] + 보조 [tail] (예: 이름 + `님 상세 정보`).
  factory DetailScreenHeadline.leadTail({
    Key? key,
    required String lead,
    required String tail,
  }) {
    return DetailScreenHeadline._(
      key: key,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            lead,
            style: const TextStyle(
              fontFamily: 'DoHyeon',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: kDetailHeadlineMuted,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tail,
            style: const TextStyle(
          fontFamily: AppTheme.brandFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FormStylePalette.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 단일 문구 (등록 화면 제목 등).
  factory DetailScreenHeadline.plain({Key? key, required String text}) {
    return DetailScreenHeadline._(
      key: key,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTheme.brandFontFamily,
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: FormStylePalette.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: headlinePadding, child: child);
  }
}

/// 가맹점·물건 상세 등 공통 **메인 탭바**
/// (화이트 배경 + 활성 탭 레드 언더라인 — 02_screens.md §4 탭바 규격).
class DetailMainTabBar extends StatelessWidget {
  const DetailMainTabBar({super.key, required this.tabTitles});

  final List<String> tabTitles;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: AppTheme.accentRed,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(const Color(0xFFF4F4F2)),
        tabs: [for (final t in tabTitles) Tab(text: t)],
      ),
    );
  }
}

/// [DefaultTabController] + 배경 + 제목 + [DetailMainTabBar] + 본문([IndexedStack], 탭별 state 유지).
class DetailScreenWithTabs extends StatefulWidget {
  const DetailScreenWithTabs({
    super.key,
    required this.title,
    required this.tabTitles,
    required this.tabPages,
  }) : assert(tabTitles.length == tabPages.length);

  final Widget title;
  final List<String> tabTitles;
  final List<Widget> tabPages;

  @override
  State<DetailScreenWithTabs> createState() => _DetailScreenWithTabsState();
}

class _DetailScreenWithTabsState extends State<DetailScreenWithTabs> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.tabTitles.length,
      child: ColoredBox(
        color: AppTheme.appSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.title,
            DetailMainTabBar(tabTitles: widget.tabTitles),
            Expanded(
              child: Builder(
                builder: (context) {
                  final controller = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return IndexedStack(
                        index: controller.index,
                        children: widget.tabPages,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 탭 없는 상세: 배경 + 제목 + [Expanded] 안 스크롤 본문.
class DetailScreenScrollBody extends StatelessWidget {
  const DetailScreenScrollBody({
    super.key,
    required this.title,
    required this.child,
  });

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
