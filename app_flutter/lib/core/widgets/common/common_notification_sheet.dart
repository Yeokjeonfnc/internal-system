// [notif_mst] 알림 목록·읽음 처리 — 중앙 다이얼로그.
//
// 실시간: 서버가 알림을 새로 넣으면 WebSocket 으로 프레임을 쏘고, 그것이
// [NotificationRealtime] 을 거쳐 여기로 온다. 예전에는 배지·목록이 화면 진입 시
// 딱 한 번만 갱신돼 새로고침 전에는 새 메일 알림이 보이지 않았다.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/core/notifications/notification_api_service.dart';
import 'package:app_flutter/core/notifications/notification_realtime.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

/// [notif_mst.notif_typ] — 활동 결재 알림.
const String _kNotifTypeActivityApproval = 'ACTIVITY_APPROVAL';

/// 로그인 유저 알림 목록을 화면 중앙 다이얼로그로 연다.
Future<void> showNotificationInboxSheet(BuildContext context) async {
  final auth = provider.Provider.of<AuthProvider>(context, listen: false);
  final uid = auth.userId.trim();
  if (uid.isEmpty) return;

  if (!context.mounted) return;
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
  StreamSubscription<NotifPushEvent>? _pushSub;

  @override
  void initState() {
    super.initState();
    _load();
    // 알림함을 열어 둔 채로 새 메일이 오는 경우. 다시 열지 않아도 목록에 들어와야 한다.
    _pushSub = NotificationRealtime.instance.stream.listen((_) {
      // silent — 보고 있던 목록이 로딩 스피너로 깜빡이면 오히려 방해가 된다.
      if (mounted) unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
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
                    final typ = row.notifTyp.trim();
                    final actIdx = row.actIdx;
                    final openApprovalDetail =
                        typ == _kNotifTypeActivityApproval && actIdx != null;
                    final read = row.readYn.toUpperCase() == 'Y';
                    final ts = row.createDt.isEmpty
                        ? ''
                        : row.createDt.split('.').first;
                    return Material(
                      color: read
                          ? erpPopupListRowBackground(i)
                          : const Color(0xFFFFF7ED),
                      child: InkWell(
                        onTap: (idx == null && !openApprovalDetail)
                            ? null
                            : () async {
                                final router = GoRouter.of(context);
                                if (idx != null) {
                                  await _api.markRead(idx, widget.userId);
                                }
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                if (openApprovalDetail) {
                                  final targetIdx = actIdx;
                                  Future.microtask(() {
                                    router.go(
                                      ActivityRoutes.approvalActivityDetail(
                                        targetIdx,
                                      ),
                                    );
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
///
/// 미읽음 수는 (1) 위젯이 뜰 때 1회, (2) 알림함을 닫을 때, 그리고
/// (3) **소켓으로 알림 푸시가 올 때마다** 다시 센다. (3)이 없으면 메일이 와도
/// 브라우저를 새로고침해야 빨간 점이 붙는다.
class NotificationBellIconButton extends StatefulWidget {
  const NotificationBellIconButton({super.key, this.currentPath = ''});

  /// 현재 열려 있는 화면 경로. 토스트 중복 억제에만 쓴다([_showMailToast]).
  ///
  /// 전역 라우터를 직접 읽지 않고 상위(앱 셸)에서 받아 오는 이유: 이 위젯은
  /// 사이드바 깊숙이 박혀 있어 라우트가 바뀌어도 자기 힘으로는 다시 그려지지
  /// 않는다. 값을 파라미터로 받으면 셸이 다시 그릴 때 자연스럽게 최신값이 온다.
  final String currentPath;

  @override
  State<NotificationBellIconButton> createState() =>
      _NotificationBellIconButtonState();
}

class _NotificationBellIconButtonState
    extends State<NotificationBellIconButton> {
  int _unread = 0;
  StreamSubscription<NotifPushEvent>? _pushSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _pushSub = NotificationRealtime.instance.stream.listen(_onPush);
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  /// 소켓 알림 도착 — 배지를 다시 세고(항상), 토스트를 띄운다(중복이 아닐 때만).
  void _onPush(NotifPushEvent event) {
    if (!mounted) return;
    unawaited(_refresh());
    if (event.isMailReceived) _showMailToast(event);
  }

  /// "새 메일이 도착했습니다" 토스트.
  ///
  /// **메일 화면에 있으면 띄우지 않는다.** 그 화면은 자기 목록을 스스로 갱신하므로
  /// 눈앞에서 메일이 늘어나는 것을 이미 보고 있는데, 그 위에 토스트까지 뜨면
  /// 같은 사실을 두 번 알리는 셈이라 방해만 된다. 배지 갱신은 이 경우에도 한다
  /// (알림함의 미읽음 표시는 메일 화면과 별개다).
  void _showMailToast(NotifPushEvent event) {
    if (widget.currentPath.startsWith(MailRoutes.root)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final detail = event.msgTxt.trim();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 380,
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF1F2937),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '새 메일이 도착했습니다.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Color(0xFFD1D5DB),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ],
          ),
          action: SnackBarAction(
            label: '보기',
            textColor: const Color(0xFFFCA5A5),
            onPressed: () {
              if (!mounted) return;
              // 개별 메일 상세로 바로 보낸다. mail_idx 가 없으면(구 프레임) 받은메일함.
              final idx = event.mailIdx;
              GoRouter.of(context).go(
                idx == null ? MailRoutes.inbox : MailRoutes.detail(idx),
              );
            },
          ),
        ),
      );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
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
