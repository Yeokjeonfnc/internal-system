import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/app_mobile_only.dart';
import 'package:app_flutter/core/layout/app_shell_top_banner.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_api.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_location_service.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_map.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_model.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_nfc_scan_sheet.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_nfc_service.dart';

/// 가맹점 출입 관리 — Android·iOS 전용 (GPS + NFC UID).
class StoreEntryView extends StatefulWidget {
  const StoreEntryView({super.key});

  @override
  State<StoreEntryView> createState() => _StoreEntryViewState();
}

class _StoreEntryViewState extends State<StoreEntryView> {
  final _locationService = StoreEntryLocationService();
  final _api = StoreEntryApiService();

  StoreEntryLocation? _location;
  StoreNfcTagLookup? _lastLookup;
  List<NearbyStoreRow> _nearby = const [];
  bool _loading = true;
  bool _nearbyLoading = false;
  bool _showMap = false;
  bool _tagging = false;
  String? _error;
  int _nearbyRequestGen = 0;

  @override
  void initState() {
    super.initState();
    if (!isNativeMobileApp) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showMobileOnlyFeatureDialog(context);
        if (mounted) context.pop();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final auth = provider.Provider.of<AuthProvider>(context, listen: false);
        final profile = auth.profile;
        if (profile == null || !profile.canUseStoreEntryTag) {
          await showAlertDialog(
            context,
            '태그 사용 권한이 없습니다.\n사원 관리에서 태그 사용을 허용해 주세요.',
          );
          if (mounted) context.pop();
          return;
        }
        await _refreshLocation();
      } catch (e, st) {
        debugPrint('[StoreEntry] bootstrap failed: $e\n$st');
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    unawaited(const StoreEntryNfcService().stopScan());
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _loading = true;
      _showMap = false;
      _error = null;
      _lastLookup = null;
      _nearby = const [];
    });
    try {
      final ok = await _locationService.ensurePermission();
      if (!ok) {
        throw StateError('위치 권한이 필요합니다. 설정에서 위치 권한을 허용해 주세요.');
      }

      final cached = await _locationService.lastKnown();
      if (cached != null && mounted) {
        setState(() {
          _location = cached;
          _loading = false;
          _showMap = true;
        });
        unawaited(_loadNearby(cached));
      }

      final loc = await _locationService.current();
      if (!mounted) return;
      final prev = _location;
      final moved = prev == null ||
          Geolocator.distanceBetween(
                prev.latitude,
                prev.longitude,
                loc.latitude,
                loc.longitude,
              ) >
              80;
      setState(() {
        _location = loc;
        _loading = false;
        _showMap = true;
      });
      if (prev == null || moved) {
        unawaited(_loadNearby(loc));
      }
    } catch (e, st) {
      debugPrint('[StoreEntry] location failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
        _showMap = false;
      });
    }
  }

  Future<void> _loadNearby(StoreEntryLocation loc) async {
    final gen = ++_nearbyRequestGen;
    if (!mounted) return;
    setState(() => _nearbyLoading = true);
    try {
      final nearby = await _api.nearbyStores(
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
      if (!mounted || gen != _nearbyRequestGen) return;
      setState(() {
        _nearby = nearby;
        _nearbyLoading = false;
      });
    } catch (e, st) {
      debugPrint('[StoreEntry] nearby failed: $e\n$st');
      if (!mounted || gen != _nearbyRequestGen) return;
      setState(() {
        _nearbyLoading = false;
        _nearby = const [];
      });
    }
  }

  void _onMapAddress(String address) {
    final loc = _location;
    if (loc == null || address.trim().isEmpty) return;
    setState(() {
      _location = StoreEntryLocation(
        latitude: loc.latitude,
        longitude: loc.longitude,
        address: address,
      );
    });
  }

  Future<void> _submitTag() async {
    final loc = _location;
    if (loc == null) {
      await showAlertDialog(context, '현재 위치를 확인할 수 없습니다.');
      return;
    }
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    final profile = auth.profile;
    if (profile == null) return;

    const nfc = StoreEntryNfcService();
    final tagUid = await showStoreEntryNfcScanSheet(context);
    if (!mounted || tagUid == null || tagUid.isEmpty) return;

    setState(() => _tagging = true);
    try {
      final lookup = await _api.lookupByTagUid(tagUid);
      if (lookup.latitude == 0 && lookup.longitude == 0) {
        throw StateError('가맹점 좌표가 등록되어 있지 않습니다.');
      }

      final distanceM = _api.distanceToStoreM(
        userLat: loc.latitude,
        userLng: loc.longitude,
        storeLat: lookup.latitude,
        storeLng: lookup.longitude,
      );
      _api.ensureWithinEntryRange(
        distanceM,
        storeNm: lookup.storeNm,
      );

      await _api.recordTag(
        userId: profile.userId,
        userNm: profile.userNm,
        deptNm: profile.deptNm,
        positionNm: profile.positionNm,
        svYn: profile.svYn,
        storeIdx: lookup.storeIdx,
        storeNm: lookup.storeNm,
        address: loc.displayAddress,
        tagUid: lookup.tagUid,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
      if (!mounted) return;
      setState(() => _lastLookup = lookup);
      await showAlertDialog(
        context,
        '${lookup.storeNm} 출입등록되었습니다.',
        title: '출입 등록',
      );
    } catch (e) {
      if (!mounted) return;
      await showAlertDialog(
        context,
        formatApiUserMessage(
          e,
          fallback: '출입 태그 등록에 실패했습니다.',
        ),
      );
    } finally {
      await nfc.releaseScanSession();
      if (mounted) setState(() => _tagging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = _location;
    final lookup = _lastLookup;

    return Scaffold(
      backgroundColor: AppTheme.appSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppShellTopBanner(
              title: '출입 관리',
              subtitle: '가맹점 NFC 출입 태그',
              compact: true,
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.listScreenHPadding,
                12,
                AppDimensions.listScreenHPadding,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                child: SizedBox(
                  height: 220,
                  child: _loading && loc == null
                      ? const ColoredBox(
                          color: AppTheme.cardBackground,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentRed,
                            ),
                          ),
                        )
                      : loc == null
                      ? ColoredBox(
                          color: AppTheme.cardBackground,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _error ?? '위치를 가져올 수 없습니다.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: FormStylePalette.textSecondary,
                                  fontFamilyFallback: AppTheme.koreanFontFallback,
                                ),
                              ),
                            ),
                          ),
                        )
                      : !_showMap
                      ? ColoredBox(
                          color: AppTheme.cardBackground,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                loc.displayAddress,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: FormStylePalette.textSecondary,
                                  fontFamilyFallback: AppTheme.koreanFontFallback,
                                ),
                              ),
                            ),
                          ),
                        )
                      : StoreEntryMapFrame(
                          key: ValueKey(
                            '${loc.latitude.toStringAsFixed(5)}_${loc.longitude.toStringAsFixed(5)}',
                          ),
                          latitude: loc.latitude,
                          longitude: loc.longitude,
                          onAddressResolved: _onMapAddress,
                        ),
                ),
              ),
            ),
            Expanded(
              child: _loading && loc == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentRed,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.listScreenHPadding,
                        12,
                        AppDimensions.listScreenHPadding,
                        0,
                      ),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.cardRadius,
                            ),
                            border: Border.all(
                              color: FormStylePalette.panelBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                                child: Text(
                                  '주변에 발견된 가맹점 목록입니다.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: FormStylePalette.accent,
                                    fontFamily: AppTheme.brandFontFamily,
                                    fontFamilyFallback:
                                        AppTheme.koreanFontFallback,
                                  ),
                                ),
                              ),
                              if (_nearby.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 14,
                                  ),
                                  child: _nearbyLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: AppTheme.accentRed,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          '주변 1km 이내 가맹점이 없습니다.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: FormStylePalette.textSecondary,
                                            fontFamilyFallback:
                                                AppTheme.koreanFontFallback,
                                          ),
                                        ),
                                )
                              else
                                ..._nearby.map(_buildStoreTile),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.cardRadius,
                            ),
                            border: Border.all(color: FormStylePalette.panelBorder),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '매장 NFC 태그를 스캔하면\n등록된 가맹점과 현재 위치(200m 이내)를 확인합니다.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: FormStylePalette.accent,
                                  fontFamilyFallback: AppTheme.koreanFontFallback,
                                ),
                              ),
                              if (lookup != null) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Text(
                                  '최근 출입: ${lookup.storeNm}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: FormStylePalette.textPrimary,
                                    fontFamilyFallback: AppTheme.koreanFontFallback,
                                  ),
                                ),
                                if (lookup.brandNm.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    lookup.brandNm,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: FormStylePalette.textSecondary,
                                      fontFamilyFallback: AppTheme.koreanFontFallback,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        if (loc != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            loc.displayAddress,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: FormStylePalette.textPrimary,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.listScreenHPadding,
                8,
                AppDimensions.listScreenHPadding,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StoreEntryActionButton(
                    label: '현재 위치 재검색',
                    icon: Icons.location_on_outlined,
                    backgroundColor: FormStylePalette.neutralGray,
                    onPressed: _loading ? null : () => unawaited(_refreshLocation()),
                  ),
                  const SizedBox(height: 10),
                  _StoreEntryActionButton(
                    label: 'NFC 태그하기',
                    icon: Icons.nfc_outlined,
                    backgroundColor: FormStylePalette.accent,
                    loading: _tagging,
                    onPressed: (_loading || _tagging || loc == null)
                        ? null
                        : () => unawaited(_submitTag()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreTile(NearbyStoreRow row) {
    final highlighted = _lastLookup?.storeIdx == row.storeIdx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: FormStylePalette.rowDivider),
        ),
        color: highlighted
            ? AppTheme.accentRed.withValues(alpha: 0.08)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.storeNm,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: highlighted
                        ? FormStylePalette.accent
                        : FormStylePalette.textPrimary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                if (row.brandLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.brandLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: FormStylePalette.textMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            row.distanceLabel,
            style: const TextStyle(
              fontSize: 14,
              color: FormStylePalette.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreEntryActionButton extends StatelessWidget {
  const _StoreEntryActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
