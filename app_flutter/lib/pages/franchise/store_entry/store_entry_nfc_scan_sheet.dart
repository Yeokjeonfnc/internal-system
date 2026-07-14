import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_nfc_service.dart';

/// NFC 태그 스캔 대기 UI. 성공 시 태그 UID, 취소 시 `null`.
Future<String?> showStoreEntryNfcScanSheet(BuildContext context) async {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetCtx) => const _StoreEntryNfcScanSheet(),
  );
}

class _StoreEntryNfcScanSheet extends StatefulWidget {
  const _StoreEntryNfcScanSheet();

  @override
  State<_StoreEntryNfcScanSheet> createState() =>
      _StoreEntryNfcScanSheetState();
}

class _StoreEntryNfcScanSheetState extends State<_StoreEntryNfcScanSheet> {
  final _nfc = const StoreEntryNfcService();
  String? _error;
  bool _tagFound = false;

  @override
  void initState() {
    super.initState();
    unawaited(_beginScan());
  }

  Future<void> _beginScan() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      await _nfc.startScan(
        onTagDiscovered: (tagUid) {
          if (!mounted) return;
          _tagFound = true;
          Navigator.of(context).pop(tagUid);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _cancel() async {
    await _nfc.stopScan();
    if (mounted) Navigator.of(context).pop(null);
  }

  @override
  void dispose() {
    if (!_tagFound) {
      unawaited(_nfc.stopScan());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '스캔 준비 완료',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FormStylePalette.accent,
                    fontFamily: AppTheme.brandFontFamily,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppTheme.appSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.nfc_rounded,
                    size: 52,
                    color: FormStylePalette.textSecondary.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ??
                      '이 화면이 뜬 뒤에만 태그를 대 주세요.\n'
                      '인식 후 휴대폰을 태그에서 떼 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _error != null
                        ? FormStylePalette.danger
                        : FormStylePalette.textSecondary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _cancel,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.appSurface,
                      foregroundColor: FormStylePalette.textPrimary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.cardRadius,
                        ),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
