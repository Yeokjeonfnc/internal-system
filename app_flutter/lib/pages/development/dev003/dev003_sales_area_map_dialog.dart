// 영업지역 지도 — 가맹점 등록·상세 등에서 팝업으로 조회.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/map/kakao_map_app_key_io.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/dev003_sales_area_map_filter_widgets.dart';
import 'package:app_flutter/pages/development/dev003/dev003_zone_info_dialog.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_map.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_view_options.dart';

final salesAreaDetailByRowIdProvider =
    FutureProvider.family<SalesAreaRow, int>((ref, rowId) async {
      return SalesAreaApiService().fetchDetailByRowId(rowId);
    });

/// [SalesAreaRow.id] 기준 영업지역 지도 팝업.
Future<void> showSalesAreaMapDialog(
  BuildContext context, {
  required int rowId,
}) async {
  if (!context.mounted) return;
  unawaited(SalesAreaApiService().prefetch());
  warmKakaoMapSdk();
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final w = (size.width - 48).clamp(720.0, 1280.0);
      final h = (size.height - 48).clamp(520.0, 920.0);
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: w,
          height: h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
                child: Row(
                  children: [
                    const Text(
                      '영업지역',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '닫기',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _SalesAreaMapDialogLoader(rowId: rowId)),
            ],
          ),
        ),
      );
    },
  );
}

class _SalesAreaMapDialogLoader extends ConsumerWidget {
  const _SalesAreaMapDialogLoader({required this.rowId});

  final int rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(salesAreaDetailByRowIdProvider(rowId));
    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '영업지역 정보를 불러오지 못했습니다.\n$e',
            style: const TextStyle(
              fontSize: 14,
              color: FormStylePalette.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ),
      data: (row) => _SalesAreaMapDialogBody(row: row, initialDetail: row),
    );
  }
}

class _SalesAreaMapDialogBody extends ConsumerStatefulWidget {
  const _SalesAreaMapDialogBody({
    required this.row,
    this.initialDetail,
  });

  final SalesAreaRow row;
  final SalesAreaRow? initialDetail;

  @override
  ConsumerState<_SalesAreaMapDialogBody> createState() =>
      _SalesAreaMapDialogBodyState();
}

class _SalesAreaMapDialogBodyState extends ConsumerState<_SalesAreaMapDialogBody> {
  final _editorKey = GlobalKey<SalesAreaEditorMapFrameState>();
  late final TextEditingController _zoneNameController;
  late final TextEditingController _addressController;
  SalesAreaEditorViewOptions _viewOptions = kSalesAreaEditorViewDefaults;
  List<CodeOption> _brandOptions = const [];
  bool _brandsLoading = true;
  bool _brandsLoadFailed = false;
  String? _selectedBrandCd;
  String _zoneInfo = '';
  SalesAreaRow? _detailRow;

  SalesAreaRow get row => widget.row;

  String? get _selectedBrandLabel {
    final cd = _selectedBrandCd;
    if (cd == null || cd.isEmpty) return null;
    for (final o in _brandOptions) {
      if (o.codeCd == cd) return o.codeNm;
    }
    final name = row.brand.trim();
    if (name.isNotEmpty && name != '-') return name;
    return null;
  }

  void _applyBrandCd(String? raw) {
    final normalized =
        salesAreaNormalizeBrandCode(raw, _brandOptions) ?? raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      _selectedBrandCd = null;
      return;
    }
    _selectedBrandCd = normalized;
  }

  @override
  void initState() {
    super.initState();
    _zoneNameController = TextEditingController(
      text: row.salesAreaName.trim().isNotEmpty
          ? row.salesAreaName.trim()
          : row.storeName.trim(),
    );
    _addressController = TextEditingController(text: row.mapAddress);
    _zoneInfo = row.zoneInfo;
    _applyBrandCd(row.brandCd);
    unawaited(_loadBrandOptions());
  }

  Future<void> _loadBrandOptions() async {
    try {
      final brands = await CommonCodeApiService().getCodes(40);
      if (!mounted) return;
      setState(() {
        _brandOptions = brands;
        _brandsLoading = false;
        _brandsLoadFailed = false;
        _applyBrandCd(_selectedBrandCd ?? row.brandCd);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _brandsLoading = false;
        _brandsLoadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onDetailLoaded(SalesAreaRow detail) {
    if (!mounted) return;
    setState(() {
      _detailRow = detail;
      _zoneInfo = detail.zoneInfo;
      _applyBrandCd(detail.brandCd);
    });
  }

  Future<void> _openZoneInfoDialog() async {
    _editorKey.currentState?.setMapPointerEvents(false);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    _editorKey.currentState?.setMapPointerEvents(false);
    try {
      await showSalesAreaZoneInfoDialog(
        context,
        initialText: _zoneInfo,
        readOnly: true,
      );
    } finally {
      if (mounted) {
        _editorKey.currentState?.setMapPointerEvents(true);
      }
    }
  }

  void _searchAddress() {
    _editorKey.currentState?.searchAddress(_addressController.text);
  }

  @override
  Widget build(BuildContext context) {
    final d = _detailRow ?? row;
    final hasMapKeys =
        d.zoneIdx != null || d.storeIdx != null || d.propIdx != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) =>
                _editorKey.currentState?.setMapPointerEvents(false),
            onPointerUp: (_) =>
                _editorKey.currentState?.setMapPointerEvents(true),
            onPointerCancel: (_) =>
                _editorKey.currentState?.setMapPointerEvents(true),
            child: SalesAreaMapAddressFilterBar(
              readOnly: true,
              addressController: _addressController,
              addressHint: row.mapAddress.isNotEmpty
                  ? row.mapAddress
                  : '주소를 입력하세요',
              onAddressSearch: _searchAddress,
              brandOptions: _brandOptions,
              selectedBrandCd: _selectedBrandCd,
              fallbackBrandLabel: row.brand,
              brandsLoading: _brandsLoading,
              brandsLoadFailed: _brandsLoadFailed,
              onBrandChanged: (cd) => setState(() => _applyBrandCd(cd)),
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
                  label: '기준거리표시',
                  value: _viewOptions.showReferenceDistance,
                  onChanged: (v) => setState(
                    () => _viewOptions = _viewOptions.copyWith(
                      showReferenceDistance: v,
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
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasMapKeys
                  ? SalesAreaEditorMapFrame(
                      key: _editorKey,
                      row: row,
                      initialDetail: widget.initialDetail,
                      readOnly: true,
                      zoneNameController: _zoneNameController,
                      viewOptions: _viewOptions,
                      brandCd: _selectedBrandCd,
                      brandLabel: _selectedBrandLabel,
                      onDetailLoaded: _onDetailLoaded,
                      onSaved: () {},
                    )
                  : const Center(
                      child: Text(
                        '영업지역·물건·가맹점 식별 정보가 없어 지도를 열 수 없습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _openZoneInfoDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                backgroundColor: const Color(0xFFFFF1F2),
                side: const BorderSide(color: Color(0xFFFCE7E8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text(
                '영업지역정보',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
