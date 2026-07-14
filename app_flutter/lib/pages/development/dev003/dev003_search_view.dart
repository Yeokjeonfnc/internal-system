import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/core/map/kakao_map_app_key_io.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_sales_area_map_filter_widgets.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_search_view_options.dart';
import 'package:app_flutter/pages/development/dev003/dev003_search_map_view.dart';

/// 영업지역 검색 — 전체 영역 지도 + 등록/상세와 동일한 주소·브랜드·보기 필터.
class SalesAreaSearchView extends StatefulWidget {
  const SalesAreaSearchView({super.key});

  @override
  State<SalesAreaSearchView> createState() => _SalesAreaSearchViewState();
}

bool _isKakaoKeyMissingMessage(String msg) {
  return msg == 'KAKAO_MAP_KEY_EMPTY' || msg.contains('설정되지 않았습니다');
}

class _SalesAreaSearchViewState extends State<SalesAreaSearchView> {
  final _keySetupController = TextEditingController();
  final _keywordController = TextEditingController();
  late final GlobalKey<SalesAreaSearchMapFrameState> _mapKey;
  String? _mapError;
  bool _showKeySetup = false;
  SalesAreaSearchViewOptions _viewOptions = kSalesAreaSearchViewDefaults;

  @override
  void initState() {
    super.initState();
    unawaited(SalesAreaApiService().prefetch());
    if (kIsWeb) {
      syncKakaoMapAppKeyToLocalStorage();
      final key = resolveKakaoMapAppKey(
        localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
      );
      _showKeySetup = key.isEmpty;
      if (key.isNotEmpty) {
        _keySetupController.text = key;
      } else {
        _keySetupController.text = kKakaoMapJavaScriptKeyDevExample;
      }
    }
    _mapKey = GlobalKey<SalesAreaSearchMapFrameState>();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _keySetupController.dispose();
    super.dispose();
  }

  void _applyKeywordFilter([String? value]) {
    final q = (value ?? _keywordController.text).trim();
    _mapKey.currentState?.filterKeyword(q);
  }

  void _resetKeywordFilter() {
    _keywordController.clear();
    _applyKeywordFilter('');
  }

  void _saveKakaoKey() {
    final key = _keySetupController.text.trim();
    if (key.isEmpty) return;
    writeKakaoMapAppKeyToLocalStorage(key);
    setState(() {
      _showKeySetup = false;
      _mapKey = GlobalKey<SalesAreaSearchMapFrameState>();
      _mapError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 14, 25, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SearchFilterTextField(
                        controller: _keywordController,
                        hint: '가맹점명 검색',
                        onChanged: _applyKeywordFilter,
                        borderRadius: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _resetKeywordFilter,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(56, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('전체'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SalesAreaMapViewOptionsBar(
                  viewOptionChecks: [
                SalesAreaViewOptionCheck(
                  label: '영업지역표시',
                  value: _viewOptions.showSalesAreas,
                  onChanged: (v) => setState(
                    () => _viewOptions = _viewOptions.copyWith(
                      showSalesAreas: v,
                    ),
                  ),
                ),
                SalesAreaViewOptionCheck(
                  label: '로드뷰 표시',
                  value: _viewOptions.showRoadView,
                  onChanged: (v) => setState(
                    () => _viewOptions = _viewOptions.copyWith(
                      showRoadView: v,
                    ),
                  ),
                ),
                SalesAreaViewOptionCheck(
                  label: '가맹점 표시',
                  value: _viewOptions.showStores,
                  onChanged: (v) => setState(
                    () => _viewOptions = _viewOptions.copyWith(
                      showStores: v,
                    ),
                  ),
                ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SalesAreaSearchMapFrame(
                  key: _mapKey,
                  viewOptions: _viewOptions,
                  onStats: (s) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        if (s.total > 0) {
                          _mapError = null;
                          _showKeySetup = false;
                        }
                      });
                    });
                  },
                  onMapError: (msg) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        if (msg.isEmpty) {
                          _mapError = null;
                          return;
                        }
                        _mapError = msg;
                        _showKeySetup = _isKakaoKeyMissingMessage(msg);
                      });
                    });
                  },
                ),
                if (_showKeySetup)
                  _KakaoKeySetupOverlay(
                    controller: _keySetupController,
                    onSave: _saveKakaoKey,
                    onDismiss: hasKakaoMapAppKeyFromDefine
                        ? null
                        : () => setState(() => _showKeySetup = false),
                  )
                else if (_mapError != null && _mapError!.contains('KAKAO'))
                  Center(child: _MapErrorBanner(message: _mapError!))
                else if (_mapError != null)
                  Center(child: _MapErrorBanner(message: _mapError!)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DEE7)),
        ),
        child: Text(
          _isKakaoKeyMissingMessage(message)
              ? 'Kakao Maps JavaScript 키가 설정되지 않았습니다.\n'
                    'app_flutter/dart_defines.local.json 또는 아래 입력 후 저장하세요.'
              : message.contains('KAKAO_SDK') ||
                    message.contains('KAKAO_SCRIPT')
              ? 'Kakao 지도 SDK를 불러오지 못했습니다.\n\n'
                    '1. developers.kakao.com → 제품 설정 → 카카오맵 → 활성화 ON\n'
                    '2. JavaScript 키 → SDK 도메인에 ${Uri.base.origin} 등록\n'
                    '3. F12 → Network → sdk.js 가 200인지 (CORS 차단 시 iframe 경로 확인)\n'
                    '4. 광고 차단 끄고 새로고침\n\n'
                    '($message)'
              : message,
          textAlign: TextAlign.center,
          style: kSearchFilterValueTextStyle.copyWith(height: 1.5),
        ),
      ),
    );
  }
}

class _KakaoKeySetupOverlay extends StatelessWidget {
  const _KakaoKeySetupOverlay({
    required this.controller,
    required this.onSave,
    this.onDismiss,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xEBF4F6F8),
      child: Center(
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9DEE7)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '지도를 불러오지 못했습니다.',
                  style: kSearchFilterValueTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kakao Maps JavaScript 키를 입력하거나\n'
                  'dart_defines.local.json 에 KAKAO_MAP_JAVASCRIPT_KEY 를 넣고\n'
                  'run_flutter_web.bat 으로 실행하세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF52606D),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SearchFilterTextField(
                  controller: controller,
                  hint: 'JavaScript 키',
                  onChanged: (_) {},
                  borderRadius: 6,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onDismiss != null)
                      TextButton(onPressed: onDismiss, child: const Text('닫기')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                      ),
                      child: const Text('저장 후 지도 열기'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
