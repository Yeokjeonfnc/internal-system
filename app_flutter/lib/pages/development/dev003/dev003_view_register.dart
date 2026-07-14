// 영업지역 상세 — 지도 편집·저장 (Flutter Web + Kakao DrawingManager).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_controller.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/dev003_sales_area_map_filter_widgets.dart';
import 'package:app_flutter/pages/development/dev003/dev003_sales_area_map_dialog.dart';
import 'package:app_flutter/pages/development/dev003/dev003_zone_info_dialog.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_map.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_view_options.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_protocol.dart';

/// 리스트에서 행을 더블클릭해 진입. [rowId]는 [SalesAreaRow.id]와 대응한다.
class SalesAreaRegisterView extends ConsumerWidget {
  const SalesAreaRegisterView({super.key, this.rowId});

  final int? rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rowId == null) {
      return ColoredBox(
        color: AppTheme.appSurface,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.listScreenHPadding,
                12,
                AppDimensions.listScreenHPadding,
                AppDimensions.listScreenBottomPadding,
              ),
              child: _RegisterBody(row: _newSalesAreaDraftRow()),
            ),
          ),
        ),
      );
    }

    final listAsync = ref.watch(dev003DataProvider);

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.contentMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.listScreenHPadding,
              12,
              AppDimensions.listScreenHPadding,
              AppDimensions.listScreenBottomPadding,
            ),
            child: listAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _LoadErrorMessage(message: '$e'),
              data: (rows) {
                SalesAreaRow? row;
                for (final r in rows) {
                  if (r.id == rowId) {
                    row = r;
                    break;
                  }
                }
                if (row == null) {
                  return _SalesAreaDetailByIdLoader(rowId: rowId!);
                }
                return _RegisterBody(row: row);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadErrorMessage extends StatelessWidget {
  const _LoadErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: const Color(0xFFE2E5EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '목록을 불러오지 못했습니다.\n$message',
          style: const TextStyle(
            fontSize: 15,
            color: kSearchFilterTextColor,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}

/// 목록 캐시에 없을 때 id로 상세 API 조회.
class _SalesAreaDetailByIdLoader extends ConsumerWidget {
  const _SalesAreaDetailByIdLoader({required this.rowId});

  final int rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(salesAreaDetailByRowIdProvider(rowId));
    return detailAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => _LoadErrorMessage(message: '$e'),
      data: (row) => _RegisterBody(row: row, initialDetail: row),
    );
  }
}

SalesAreaRow _newSalesAreaDraftRow() {
  return const SalesAreaRow(
    id: 0,
    storeIdx: null,
    zoneIdx: null,
    propIdx: null,
    settingDateYmd: '',
    propertyName: '',
    regionCd: '',
    region: '',
    franchiseLabel: '-',
    storeName: '신규 영업지역',
    brand: '-',
    brandCd: '',
    areaSettingLabel: '전략출점',
    salesAreaName: '',
    isAreaConfigured: false,
    isStrategicOpening: true,
    isFranchise: false,
    mapAddress: '',
    latitude: null,
    longitude: null,
    geometryType: null,
    geometry: null,
  );
}

class _RegisterBody extends ConsumerStatefulWidget {
  const _RegisterBody({required this.row, this.initialDetail});

  final SalesAreaRow row;
  final SalesAreaRow? initialDetail;

  @override
  ConsumerState<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends ConsumerState<_RegisterBody> {
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

  /// Web IME 조합(composing) 범위를 비워서 TextInput assertion을 방지한다.
  void _setControllerTextSafely(TextEditingController controller, String text) {
    final normalized = text;
    if (controller.text == normalized) return;
    controller.value = controller.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(SalesAreaApiService().prefetch());
    final initial = row.salesAreaName.trim().isNotEmpty
        ? row.salesAreaName.trim()
        : row.storeName.trim();
    _zoneNameController = TextEditingController(text: initial);
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

  void _onSaveError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onSaved() {
    ref.invalidate(dev003DataProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('영업지역이 저장되었습니다.')));
  }

  void _onDetailLoaded(SalesAreaRow detail) {
    if (!mounted) return;
    setState(() {
      _detailRow = detail;
      _zoneInfo = detail.zoneInfo;
      _applyBrandCd(detail.brandCd);
      final zoneNm = detail.salesAreaName.trim();
      if (zoneNm.isNotEmpty && _zoneNameController.text.trim().isEmpty) {
        _setControllerTextSafely(_zoneNameController, zoneNm);
      }
    });
  }

  Future<void> _openZoneInfoDialog(bool canEdit) async {
    // Web: Kakao iframe이 다이얼로그 위에서 클릭·키보드를 가로챔
    _editorKey.currentState?.setMapPointerEvents(false);
    // 좌측 패널 pointerUp이 iframe을 다시 켜는 타이밍과 겹치므로 한 번 더 끔
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    _editorKey.currentState?.setMapPointerEvents(false);
    try {
      final result = await showSalesAreaZoneInfoDialog(
        context,
        initialText: _zoneInfo,
        readOnly: !canEdit,
      );
      if (!canEdit || result == null || !mounted) return;

      final d = _detailRow ?? row;
      try {
        final saved = await SalesAreaApiService().saveZoneInfo(
          zoneIdx: d.zoneIdx,
          propIdx: d.propIdx,
          storeIdx: d.storeIdx,
          zoneInfo: result,
        );
        if (!mounted) return;
        setState(() {
          _zoneInfo = saved.zoneInfo;
          _detailRow = saved;
        });
        ref.invalidate(dev003DataProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('영업지역정보가 저장되었습니다.')));
      } catch (e) {
        _onSaveError('$e');
      }
    } finally {
      if (mounted) {
        _editorKey.currentState?.setMapPointerEvents(true);
      }
    }
  }

  void _searchAddress() {
    _editorKey.currentState?.searchAddress(_addressController.text);
  }

  bool get _isNew => row.id == 0;

  bool _canEdit(BuildContext context) {
    return _isNew
        ? context.menuCanCreate(kMenuDev003)
        : context.menuCanUpdate(kMenuDev003);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit(context);
    final compact = useCompactErpLayout(context);
    // 앱: 권한과 무관하게 조회 전용. Web 에서만 그리기·측정·저장.
    final mapReadOnly = !canEdit || compact;
    final showEditTools = canEdit && !compact;

    Widget buildMap() {
      if (row.id != 0 &&
          row.zoneIdx == null &&
          row.storeIdx == null &&
          row.propIdx == null) {
        return const Center(
          child: Text(
            '영업지역·물건·가맹점 식별 정보가 없어 지도를 열 수 없습니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        );
      }
      return SalesAreaEditorMapFrame(
        key: _editorKey,
        row: row,
        initialDetail: widget.initialDetail ??
            (row.needsSalesAreaDetailFetch ? null : row),
        readOnly: mapReadOnly,
        zoneNameController: _zoneNameController,
        viewOptions: _viewOptions,
        brandCd: _selectedBrandCd,
        brandLabel: _selectedBrandLabel,
        onDetailLoaded: _onDetailLoaded,
        onAddressResolved: (address) {
          if (!mounted) return;
          _setControllerTextSafely(_addressController, address);
        },
        onSaved: _onSaved,
        onSaveError: _onSaveError,
      );
    }

    final addressBar = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _editorKey.currentState?.setMapPointerEvents(false),
      onPointerUp: (_) => _editorKey.currentState?.setMapPointerEvents(true),
      onPointerCancel: (_) => _editorKey.currentState?.setMapPointerEvents(true),
      child: SalesAreaMapAddressFilterBar(
        readOnly: mapReadOnly,
        viewOptionsHorizontal: useCompactErpLayout(context),
        addressController: _addressController,
        addressHint: row.mapAddress.isNotEmpty ? row.mapAddress : '주소를 입력하세요',
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
              () => _viewOptions = _viewOptions.copyWith(showSalesAreas: v),
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
              () => _viewOptions = _viewOptions.copyWith(showStores: v),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  _isNew
                      ? '등록 권한이 없습니다. 영업지역을 등록하려면 메뉴 권한(등록)이 필요합니다.'
                      : '조회 권한만 있습니다. 영업지역을 수정하려면 메뉴 권한(수정)이 필요합니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ),
          ),
        Text(
          row.id == 0 ? '영업지역 등록' : row.detailHeadline,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: FormStylePalette.textPrimary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.id == 0 ? '전략출점 신규 등록' : row.propertyName,
          style: const TextStyle(
            fontSize: 13,
            color: kDetailHeadlineMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: const Color(0xFFE2E5EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        addressBar,
                        const SizedBox(height: 12),
                        _LeftToolColumn(
                          readOnly: mapReadOnly,
                          showEditTools: showEditTools,
                          editorKey: _editorKey,
                          zoneNameController: _zoneNameController,
                          onZoneInfo: () => _openZoneInfoDialog(canEdit),
                          onDrawPolygon: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdDrawPolygon),
                          onDrawCircle: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdDrawCircle),
                          onDrawReferenceCircle: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdDrawReferenceCircle),
                          onDistanceMeasure: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdDistanceMeasure),
                          onRadiusMeasure: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdRadiusMeasure),
                          onClearDrawing: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdClearDrawing),
                          onClearMeasure: () => _editorKey.currentState
                              ?.sendCommand(kSalesAreaCmdClearMeasure),
                          onSave: () =>
                              _editorKey.currentState?.requestSaveFromMap(),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: buildMap(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        addressBar,
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 280,
                                child: _LeftToolColumn(
                                  readOnly: mapReadOnly,
                                  showEditTools: showEditTools,
                                  editorKey: _editorKey,
                                  zoneNameController: _zoneNameController,
                                  onZoneInfo: () =>
                                      _openZoneInfoDialog(canEdit),
                                  onDrawPolygon: () => _editorKey.currentState
                                      ?.sendCommand(kSalesAreaCmdDrawPolygon),
                                  onDrawCircle: () => _editorKey.currentState
                                      ?.sendCommand(kSalesAreaCmdDrawCircle),
                                  onDrawReferenceCircle: () =>
                                      _editorKey.currentState?.sendCommand(
                                        kSalesAreaCmdDrawReferenceCircle,
                                      ),
                                  onDistanceMeasure: () =>
                                      _editorKey.currentState?.sendCommand(
                                        kSalesAreaCmdDistanceMeasure,
                                      ),
                                  onRadiusMeasure: () => _editorKey.currentState
                                      ?.sendCommand(
                                        kSalesAreaCmdRadiusMeasure,
                                      ),
                                  onClearDrawing: () => _editorKey.currentState
                                      ?.sendCommand(kSalesAreaCmdClearDrawing),
                                  onClearMeasure: () => _editorKey.currentState
                                      ?.sendCommand(kSalesAreaCmdClearMeasure),
                                  onSave: () => _editorKey.currentState
                                      ?.requestSaveFromMap(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: buildMap(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeftToolColumn extends StatelessWidget {
  const _LeftToolColumn({
    this.readOnly = false,
    this.showEditTools = true,
    required this.editorKey,
    required this.zoneNameController,
    required this.onZoneInfo,
    required this.onDrawPolygon,
    required this.onDrawCircle,
    required this.onDrawReferenceCircle,
    required this.onDistanceMeasure,
    required this.onRadiusMeasure,
    required this.onClearDrawing,
    required this.onClearMeasure,
    required this.onSave,
  });

  final bool readOnly;
  final bool showEditTools;
  final GlobalKey<SalesAreaEditorMapFrameState> editorKey;
  final TextEditingController zoneNameController;
  final VoidCallback onZoneInfo;
  final VoidCallback onDrawPolygon;
  final VoidCallback onDrawCircle;
  final VoidCallback onDrawReferenceCircle;
  final VoidCallback onDistanceMeasure;
  final VoidCallback onRadiusMeasure;
  final VoidCallback onClearDrawing;
  final VoidCallback onClearMeasure;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => editorKey.currentState?.setMapPointerEvents(false),
      onPointerUp: (_) => editorKey.currentState?.setMapPointerEvents(true),
      onPointerCancel: (_) => editorKey.currentState?.setMapPointerEvents(true),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '영업지역명',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kSearchFilterTextColor,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: zoneNameController,
              readOnly: readOnly,
              decoration: const InputDecoration(
                hintText: '영업지역명을 입력하세요',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onZoneInfo,
              style: FilledButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                backgroundColor: const Color(0xFFFFF1F2),
                side: const BorderSide(color: Color(0xFFFCE7E8)),
              ),
              child: const Text(
                '영업지역정보',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 161, 4, 43),
                ),
              ),
            ),
            if (showEditTools) ...[
              const SizedBox(height: 14),
              const Text(
                '영업지역 설정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kSearchFilterTextColor,
                ),
              ),
              const SizedBox(height: 6),
              _ToolButton(
                label: '다각형 그리기',
                onPressed: onDrawPolygon,
                onClear: onClearDrawing,
              ),
              _ToolButton(
                label: '원형 그리기',
                onPressed: onDrawCircle,
                onClear: onClearDrawing,
              ),
              _ToolButton(label: '기준거리로 그리기', onPressed: onDrawReferenceCircle),
              const SizedBox(height: 14),
              const Text(
                '거리 측정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kSearchFilterTextColor,
                ),
              ),
              const SizedBox(height: 6),
              _ToolButton(
                label: '거리 측정',
                onPressed: onDistanceMeasure,
                onClear: onClearMeasure,
              ),
              _ToolButton(
                label: '반경 측정',
                onPressed: onRadiusMeasure,
                onClear: onClearMeasure,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.onPressed,
    this.onClear,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (onClear != null) ...[
            SizedBox(
              width: 32,
              child: FilledButton.tonal(
                onPressed: onClear,
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                child: const Text('×'),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: FilledButton.tonal(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                backgroundColor: const Color(0xFFFFF1F2),
                side: const BorderSide(color: Color(0xFFFCE7E8)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
