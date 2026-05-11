// [notif_mst] 알림 목록·읽음 처리 — 중앙 다이얼로그.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/core/notifications/notification_api_service.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/pages/active/activity_routes.dart';

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
          child: FutureBuilder<List<NotifRow>>(
            future: NotificationApiService().list(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snapshot.data ?? const <NotifRow>[];
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
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: rows.isEmpty
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
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              final idx = row.notifIdx;
                              final msg = row.msgTxt;
                              final typ = row.notifTyp.trim();
                              final actIdx = row.actIdx;
                              final openApprovalDetail =
                                  typ == _kNotifTypeActivityApproval &&
                                  actIdx != null;
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
                                          final router = GoRouter.of(dialogCtx);
                                          if (idx != null) {
                                            await NotificationApiService()
                                                .markRead(idx, uid);
                                          }
                                          if (!dialogCtx.mounted) return;
                                          Navigator.of(dialogCtx).pop();
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                ],
              );
            },
          ),
        ),
      );
    },
  );
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
