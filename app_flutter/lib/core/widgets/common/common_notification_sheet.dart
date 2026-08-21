// [notif_mst] 알림 목록·읽음 처리 — 중앙 다이얼로그.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/core/notifications/notif_open.dart';
import 'package:app_flutter/core/notifications/notification_api_service.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';

/// 로그인 유저 알림 목록을 화면 중앙 다이얼로그로 연다.
Future<void> showNotificationInboxSheet(BuildContext context) async {
  final auth = provider.Provider.of<AuthProvider>(context, listen: false);
  final uid = auth.userId.trim();
  if (uid.isEmpty) return;

  if (!context.mounted) return;
  await IframePointerGate.whileBlocked(() async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final size = MediaQuery.sizeOf(dialogCtx);
        final maxH = size.height * 0.72;
        final maxW = math.min(520.0, size.width - 64);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.white,
          child: SizedBox(
            width: maxW,
            height: maxH,
            child: _NotificationInboxDialog(userId: uid),
          ),
        );
      },
    );
  });
}

class _NotificationInboxDialog extends StatefulWidget {
  const _NotificationInboxDialog({required this.userId});

  final String userId;

  @override
  State<_NotificationInboxDialog> createState() =>
      _NotificationInboxDialogState();
}

class _NotificationInboxDialogState extends State<_NotificationInboxDialog> {
  final _api = NotificationApiService();
  bool _loading = true;
  bool _markingAll = false;
  List<NotifRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _api.list(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rows = rows;
    });
  }

  bool get _hasUnread => _rows.any((r) => r.readYn.toUpperCase() != 'Y');

  Future<void> _markAllRead() async {
    if (!_hasUnread || _markingAll) return;
    setState(() => _markingAll = true);
    final ok = await _api.markAllRead(widget.userId);
    if (!mounted) return;
    setState(() => _markingAll = false);
    if (ok) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              const Text(
                '알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
              ? const Center(
                  child: Text(
                    '알림이 없습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final row = _rows[i];
                    final idx = row.notifIdx;
                    final msg = row.msgTxt;
                    final openRoute = notifOpenRoute(row);
                    final read = row.readYn.toUpperCase() == 'Y';
                    final ts = row.createDt.isEmpty
                        ? ''
                        : row.createDt.split('.').first;
                    return Material(
                      color: read
                          ? erpPopupListRowBackground(i)
                          : const Color(0xFFFFF7ED),
                      child: InkWell(
                        onTap: (idx == null && openRoute == null)
                            ? null
                            : () async {
                                final router = GoRouter.of(context);
                                if (idx != null) {
                                  await _api.markRead(idx, widget.userId);
                                }
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                if (openRoute != null) {
                                  final target = openRoute;
                                  Future.microtask(() {
                                    router.go(target);
                                  });
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  fontFamilyFallback:
                                      AppTheme.koreanFontFallback,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ts,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamilyFallback:
                                      AppTheme.koreanFontFallback,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (!_loading && _rows.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              child: FilledButton(
                onPressed: _hasUnread && !_markingAll ? _markAllRead : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _markingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '모두 읽음',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 사이드바 프로필 줄 — 설정 버튼 왼쪽 알림(미읽음 점).
class NotificationBellIconButton extends StatefulWidget {
  const NotificationBellIconButton({super.key});

  @override
  State<NotificationBellIconButton> createState() =>
      _NotificationBellIconButtonState();
}

class _NotificationBellIconButtonState
    extends State<NotificationBellIconButton> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId.trim();
    if (uid.isEmpty) return;
    final n = await NotificationApiService().unreadCount(uid);
    if (mounted) setState(() => _unread = n);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '알림',
      onPressed: () async {
        await showNotificationInboxSheet(context);
        await _refresh();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_outlined, size: 18),
          if (_unread > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      color: const Color(0xFFADB5BD),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
