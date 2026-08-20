// 메인 대시보드 화면(지표·계약 카드 그리드).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/notifications/notification_api_service.dart';
import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/core/router/app_router.dart' show AppRoutes;
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_responsive_grid.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/franchise/str001/str001_api.dart';
import 'package:provider/provider.dart' as provider;
import 'package:go_router/go_router.dart';

/// 대시보드 전용 팔레트 — 2026 리디자인(01_design_system.md) 라이트 톤.
abstract final class _DashPalette {
  static const bg = AppTheme.appSurface;
  static const card = Colors.white;
  static const cardElevated = AppTheme.tableHeaderBackground;
  static const divider = AppTheme.hairline;
  static const coral = AppTheme.accentRed;
  static const pink = AppTheme.statusPending;
  static const cyan = AppTheme.statusRenewal;
  static const textOnDark = AppTheme.textPrimary;
  static const textMuted = AppTheme.textMuted;
}

/// 세션 캐시 — 재진입 시 즉시 표시(keepAlive), 저장 흐름에서 invalidate.
final dashboardHomeDataProvider =
    FutureProvider.family<_DashboardHomeData, String>((ref, uid) {
  return _loadDashboardHomeData(uid);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = provider.Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userId.trim();
    final dataAsync = ref.watch(dashboardHomeDataProvider(uid));
    return ColoredBox(
      color: _DashPalette.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Builder(
          builder: (context) {
            final data = dataAsync.valueOrNull;
            if (data == null && dataAsync.isLoading) {
              return const SizedBox(
                height: 420,
                child: Center(
                  child: CircularProgressIndicator(color: _DashPalette.coral),
                ),
              );
            }
            if (data == null) {
              return const SizedBox(
                height: 420,
                child: Center(
                  child: Text(
                    '대시보드 데이터를 불러오지 못했습니다.',
                    style: TextStyle(color: _DashPalette.textMuted),
                  ),
                ),
              );
            }

            const gridGap = 16.0;

            final statCards = [
              _StatAccentCard(
                value: '${data.pendingNotifCount}건',
                label: '결재 알림',
                sublabel: '처리 대기',
                accent: _DashPalette.coral,
              ),
              _StatAccentCard(
                value: '${data.newStoresThisMonth}',
                label: '이번 달 신규',
                sublabel: '가맹점',
                accent: AppTheme.statusNew,
              ),
              _StatAccentCard(
                value: '${data.expiringStoresThisMonth}',
                label: '이번 달 만료',
                sublabel: '예정 가맹점',
                accent: _DashPalette.pink,
              ),
              _StatAccentCard(
                value: '${data.totalStores}',
                label: '총 가맹점',
                sublabel: '운영 중',
                accent: _DashPalette.cyan,
              ),
            ];

            final contentCards = [
              _RecentNotifsCard(recentNotifs: data.recentNotifs, userId: uid),
              _StoreChangesCard(
                newStoresThisMonth: data.newStoresThisMonth,
                expiringStoresThisMonth: data.expiringStoresThisMonth,
                totalStores: data.totalStores,
              ),
              _RecentActivitiesCard(
                recentActivities: data.recentActivities,
                userId: uid,
              ),
              const _CalendarCard(),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveCardGrid(
                  minItemWidth: 200,
                  spacing: gridGap,
                  runSpacing: gridGap,
                  children: statCards,
                ),
                const SizedBox(height: gridGap + 4),
                ResponsiveCardGrid(
                  minItemWidth: 380,
                  maxColumns: 2,
                  spacing: gridGap,
                  runSpacing: gridGap,
                  children: contentCards,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dashboard 4 cards implementation (요구사항 1~4)
// -----------------------------------------------------------------------------

class _DashboardHomeData {
  const _DashboardHomeData({
    required this.recentNotifs,
    required this.pendingNotifCount,
    required this.newStoresThisMonth,
    required this.expiringStoresThisMonth,
    required this.totalStores,
    required this.recentActivities,
  });

  /// 카드에 그릴 최근 알림(최대 5건) — 개수 표시용이 아니다.
  final List<NotifRow> recentNotifs;

  /// KPI '처리 대기' 건수 — 자르기 전 전체에서 미읽음·미결재만 센 값.
  final int pendingNotifCount;
  final int newStoresThisMonth;
  final int expiringStoresThisMonth;
  final int totalStores;
  final List<ActivityRow> recentActivities;
}

const String _kNotifTypeActivityApproval = 'ACTIVITY_APPROVAL';

/// Y/N 플래그 판정 — 알림 시트(common_notification_sheet.dart)와 같은 기준.
bool _isYesFlag(String raw) => raw.trim().toUpperCase() == 'Y';

bool _isSameMonth(String raw, DateTime now) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  final dt =
      DateTime.tryParse(s) ??
      (s.length >= 10 ? DateTime.tryParse(s.substring(0, 10)) : null);
  if (dt == null) return false;
  return dt.year == now.year && dt.month == now.month;
}

String _formatShortDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  if (s.contains('T')) return s.split('T').first;
  if (s.contains('.')) return s.split('.').first;
  return s.length >= 10 ? s.substring(0, 10) : s;
}

Future<_DashboardHomeData> _loadDashboardHomeData(String userId) async {
  final uid = userId.trim();
  final now = DateTime.now();

  if (uid.isEmpty) {
    return const _DashboardHomeData(
      recentNotifs: [],
      pendingNotifCount: 0,
      newStoresThisMonth: 0,
      expiringStoresThisMonth: 0,
      totalStores: 0,
      recentActivities: [],
    );
  }

  // 세 API는 서로 독립이므로 병렬 호출한다(직렬 시 왕복 3회 ≈ 2.8초 → 1회 수준).
  final notifsFuture = NotificationApiService().list(uid);
  final storesFuture = StoreApiService().getAllStores();
  final approvalsFuture = Act002Api().fetchPendingAndApprovedRowsForRelUser(
    uid,
  );
  final notifsAll = await notifsFuture;
  final stores = await storesFuture;
  final approvalRows = await approvalsFuture;

  final approvalNotifs = notifsAll
      .where(
        (n) =>
            n.notifTyp.trim() == _kNotifTypeActivityApproval &&
            n.actIdx != null,
      )
      .toList();

  // KPI 는 자르기 전 전체에서 세고(take(5) 하면 항상 '5건'), 이미 읽었거나
  // 결재까지 끝난 알림은 '처리 대기' 가 아니므로 제외한다.
  final pendingNotifCount = approvalNotifs
      .where((n) => !_isYesFlag(n.readYn) && !_isYesFlag(n.apprYn))
      .length;

  final recentNotifs = approvalNotifs.take(5).toList();

  final totalStores = stores.length;
  final newStoresThisMonth = stores
      .where((s) => _isSameMonth(s.firstContDt, now))
      .length;
  final expiringStoresThisMonth = stores
      .where((s) => _isSameMonth(s.contEndDt, now))
      .length;

  final recentActivities = approvalRows.take(5).toList();

  return _DashboardHomeData(
    recentNotifs: recentNotifs,
    pendingNotifCount: pendingNotifCount,
    newStoresThisMonth: newStoresThisMonth,
    expiringStoresThisMonth: expiringStoresThisMonth,
    totalStores: totalStores,
    recentActivities: recentActivities,
  );
}

/// KPI 스트립 한 칸 — 플랫(01_design_system.md §4 KPI 카드 규격).
class _StatAccentCard extends StatelessWidget {
  const _StatAccentCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.accent,
  });

  final String value;
  final String label;
  final String sublabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCardShell extends StatelessWidget {
  const _DashboardCardShell({
    required this.title,
    this.subtitle,
    this.onTap,
    this.accentColor = _DashPalette.coral,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: _DashPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: accentColor,
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _RecentNotifsCard extends StatelessWidget {
  const _RecentNotifsCard({required this.recentNotifs, required this.userId});

  final List<NotifRow> recentNotifs;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      title: '최근 알림',
      subtitle: '탭하여 상세 이동',
      accentColor: _DashPalette.coral,
      child: SizedBox(
        height: 248,
        child: recentNotifs.isEmpty
            ? const _EmptyPanel(message: '알림이 없습니다.')
            : ListView.separated(
                itemCount: recentNotifs.length,
                separatorBuilder: (context, _) =>
                    const Divider(height: 1, color: _DashPalette.divider),
                itemBuilder: (context, i) {
                  final row = recentNotifs[i];
                  final msg = row.msgTxt.trim();
                  final ts = _formatShortDate(row.createDt);
                  final actIdx = row.actIdx;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: (actIdx == null)
                          ? null
                          : () async {
                              final notifIdx = row.notifIdx;
                              if (notifIdx != null) {
                                await NotificationApiService().markRead(
                                  notifIdx,
                                  userId,
                                );
                              }
                              if (!context.mounted) return;
                              context.go(
                                ActivityRoutes.approvalActivityDetail(actIdx),
                              );
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _DashPalette.coral.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.mail_outline,
                                size: 18,
                                color: _DashPalette.coral,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.isEmpty ? '-' : msg,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _DashPalette.textOnDark,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ts,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _DashPalette.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
    );
  }
}

class _StoreChangesCard extends StatelessWidget {
  const _StoreChangesCard({
    required this.newStoresThisMonth,
    required this.expiringStoresThisMonth,
    required this.totalStores,
  });

  final int newStoresThisMonth;
  final int expiringStoresThisMonth;
  final int totalStores;

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      title: '가맹점 현황',
      subtitle: '가맹점관리 메뉴로 이동',
      accentColor: _DashPalette.cyan,
      onTap: () => context.go(AppRoutes.stores),
      child: SizedBox(
        height: 248,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StoreMetricBar(
              label: '신규',
              value: newStoresThisMonth,
              max: totalStores > 0 ? totalStores : 1,
              color: _DashPalette.coral,
            ),
            const SizedBox(height: 14),
            _StoreMetricBar(
              label: '만료 예정',
              value: expiringStoresThisMonth,
              max: totalStores > 0 ? totalStores : 1,
              color: _DashPalette.pink,
            ),
            const SizedBox(height: 14),
            _StoreMetricBar(
              label: '총 가맹점',
              value: totalStores,
              max: totalStores > 0 ? totalStores : 1,
              color: _DashPalette.cyan,
              filled: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreMetricBar extends StatelessWidget {
  const _StoreMetricBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.filled = false,
  });

  final String label;
  final int value;
  final int max;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ratio = filled ? 1.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _DashPalette.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: _DashPalette.cardElevated,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  const _RecentActivitiesCard({
    required this.recentActivities,
    required this.userId,
  });

  final List<ActivityRow> recentActivities;
  final String userId;

  String _statusLabel(String raw) {
    return switch (raw.trim().toUpperCase()) {
      'PENDING' => '결재대기',
      'APPROVED' => '결재완료',
      _ => raw.trim().isEmpty ? '-' : raw.trim(),
    };
  }

  Color _chipFg(String raw) {
    final r = raw.trim().toUpperCase();
    return r == 'PENDING'
        ? AppTheme.statusPending
        : r == 'APPROVED'
        ? AppTheme.statusNew
        : _DashPalette.textMuted;
  }

  Color _chipBg(String raw) {
    return _chipFg(raw).withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      title: '활동 관리 등록',
      subtitle: '활동관리결재 메뉴로 이동',
      accentColor: _DashPalette.pink,
      onTap: () => context.go(ActivityRoutes.approvalAll),
      child: SizedBox(
        height: 300,
        child: recentActivities.isEmpty
            ? const _EmptyPanel(message: '등록된 활동이 없습니다.')
            : ListView.separated(
                itemCount: recentActivities.length,
                separatorBuilder: (context, _) =>
                    const Divider(height: 1, color: _DashPalette.divider),
                itemBuilder: (context, i) {
                  final row = recentActivities[i];
                  final actIdx = row.actIdx;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: (actIdx == null)
                          ? null
                          : () => context.go(
                              ActivityRoutes.approvalActivityDetail(actIdx),
                            ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _DashPalette.cardElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatShortDate(row.actDt)}  ·  ${row.storeNm}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _DashPalette.textOnDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Text(
                            //   row.actNotes.trim().isEmpty
                            //       ? '-'
                            //       : row.actNotes.trim(),
                            //   maxLines: 2,
                            //   overflow: TextOverflow.ellipsis,
                            //   style: const TextStyle(
                            //     fontSize: 13,
                            //     fontWeight: FontWeight.w500,
                            //     color: _DashPalette.textMuted,
                            //     height: 1.35,
                            //   ),
                            // ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _chipBg(row.apprStatus),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(row.apprStatus),
                                style: TextStyle(
                                  color: _chipFg(row.apprStatus),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
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
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: _DashPalette.textMuted.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: _DashPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatefulWidget {
  const _CalendarCard();

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      title: '달력',
      subtitle: '활동 계획으로 이동',
      accentColor: _DashPalette.cyan,
      onTap: () => context.go(ActivityRoutes.calendar),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _DashPalette.cyan,
            onPrimary: Colors.white,
            onSurface: _DashPalette.textOnDark,
            surface: _DashPalette.card,
          ),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: _DashPalette.textOnDark,
            displayColor: _DashPalette.textOnDark,
          ),
        ),
        child: SizedBox(
          height: 300,
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(DateTime.now().year - 1, 1, 1),
            lastDate: DateTime(DateTime.now().year + 1, 12, 31),
            onDateChanged: (d) {
              setState(() => _selectedDate = d);
              context.go(ActivityRoutes.calendar);
            },
          ),
        ),
      ),
    );
  }
}
