import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_field_block.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_api.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_nfc_uid.dart';

/// 가맹점 상세 — NFC 태그 UID 등록(1매장 1태그).
class StoreNfcTagPanel extends StatefulWidget {
  const StoreNfcTagPanel({
    super.key,
    required this.storeIdx,
    this.canEdit = true,
  });

  final int storeIdx;
  final bool canEdit;

  @override
  State<StoreNfcTagPanel> createState() => _StoreNfcTagPanelState();
}

class _StoreNfcTagPanelState extends State<StoreNfcTagPanel> {
  final _api = StoreNfcTagApiService();
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _registeredUid;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final row = await _api.fetchByStore(widget.storeIdx);
      if (!mounted) return;
      _registeredUid = row?.tagUid;
      _controller.text = _formatUidForDisplay(row?.tagUid ?? '');
    } catch (e) {
      debugPrint('[StoreNfcTagPanel] load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatUidForDisplay(String uid) {
    final n = normalizeNfcTagUid(uid);
    if (n.length < 8) return n;
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i += 2) {
      if (i > 0) buf.write(':');
      final end = (i + 2 <= n.length) ? i + 2 : n.length;
      buf.write(n.substring(i, end));
    }
    return buf.toString();
  }

  Future<void> _save() async {
    final uid = normalizeNfcTagUid(_controller.text.trim());
    if (uid.isEmpty) {
      await showAlertDialog(context, 'NFC 태그 UID를 입력해 주세요.');
      return;
    }
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    setState(() => _saving = true);
    try {
      await _api.register(
        storeIdx: widget.storeIdx,
        tagUid: uid,
        registeredBy: auth.userId,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      await showAlertDialog(context, 'NFC 태그가 등록되었습니다.');
    } catch (e) {
      if (!mounted) return;
      await showAlertDialog(
        context,
        formatApiUserMessage(e, fallback: 'NFC 태그 저장에 실패했습니다.'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('확인'),
        content: const Text('등록된 NFC 태그를 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _api.remove(widget.storeIdx);
      if (!mounted) return;
      _controller.clear();
      _registeredUid = null;
      setState(() {});
      await showAlertDialog(context, 'NFC 태그 등록이 해제되었습니다.');
    } catch (e) {
      if (!mounted) return;
      await showAlertDialog(
        context,
        formatApiUserMessage(e, fallback: 'NFC 태그 해제에 실패했습니다.'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: 'NFC 태그 UID',
            child: widget.canEdit
                ? TextField(
                    controller: _controller,
                    style: FormStylePalette.valueStyle,
                    decoration: InputDecoration(
                      hintText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : ReadonlyValue(
                    _registeredUid == null
                        ? '미등록'
                        : _formatUidForDisplay(_registeredUid!),
                  ),
          ),
          right: widget.canEdit
              ? FormFieldBlock(
                  label: ' ',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => unawaited(_save()),
                          child: Text(_saving ? '저장 중…' : 'UID 저장'),
                        ),
                      ),
                      if (_registeredUid != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => unawaited(_remove()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FormStylePalette.danger,
                          ),
                          child: const Text('해제'),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
