// 마스터 — 사원관리 목록(필터·테이블).

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/master/mst001/mst001_csv.dart';
import 'package:app_flutter/pages/master/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_repo.dart';
import 'package:app_flutter/core/router/app_router.dart';

/// 직급 코드 그룹 (`grp_cd = 60`) — 사원 상세 화면과 같은 값.
const int _kUserPositionGrpCd = 60;

void _flattenDepartmentTree(List<Department> roots, List<Department> out) {
  for (final d in roots) {
    out.add(d);
    _flattenDepartmentTree(d.children, out);
  }
}

/// 사원관리 목록.
class UserListView extends ConsumerStatefulWidget {
  const UserListView({super.key});

  @override
  ConsumerState<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends ConsumerState<UserListView> {
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(userProvider);
    _keywordCtrl = TextEditingController(text: s.userKeyword);
    Future.microtask(() => ref.read(userProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  /// 목록에 실제로 나타난 부서명·직급명(필터 규칙과 동일하게 문자열 비교).
  List<String> _distinctSorted(Iterable<String> raw) {
    final out = raw
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    out.sort();
    return out;
  }

  SearchFilterItemData _departmentFilterItem(
    UserFilter filter,
    List<String> departmentNames,
    UserNotifier n,
  ) {
    return FilterDropdownSlot<String>(
      label: '부서',
      value: filter.department,
      items: [
        const DropdownMenuItem<String?>(value: '전체', child: Text('전체')),
        for (final name in departmentNames)
          DropdownMenuItem<String?>(value: name, child: Text(name)),
      ],
      onChanged: (v) => n.setDepartment(v ?? '전체'),
    ).toItem();
  }

  SearchFilterItemData _positionFilterItem(
    UserFilter filter,
    List<String> positionNames,
    UserNotifier n,
  ) {
    return FilterStringOptionsSlot(
      label: '직급',
      value: filter.position,
      options: ['전체', ...positionNames],
      onSelected: n.setPosition,
      forceDropdown: true,
    ).toItem();
  }

  Widget _buildFilterRow(
    UserFilter filter,
    List<String> departmentNames,
    List<String> positionNames,
    UserNotifier n,
  ) {
    return SearchFilterStackedItems(
      items: [
        _departmentFilterItem(filter, departmentNames, n),
        _positionFilterItem(filter, positionNames, n),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProvider);
    final listAsync = ref.watch(userDataProvider);
    return listAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.read(userProvider.notifier).refresh(),
            child: const Text('목록을 불러오지 못했습니다. 다시 시도'),
          ),
        ),
      ),
      data: (users) {
        final filter = ref.watch(userProvider);
        final n = ref.read(userProvider.notifier);
        final rows = n.getFilteredList();
        final departmentNames = _distinctSorted(users.map((u) => u.department));
        final positionNames = _distinctSorted(users.map((u) => u.positionNm));

        final mainBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchFilterTextField(
              controller: _keywordCtrl,
              hint: '키워드 검색',
              borderRadius: 8,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade500,
                size: 22,
              ),
              onChanged: n.setUserKeyword,
            ),
            const SizedBox(height: 8),
            _buildFilterRow(
              filter,
              departmentNames,
              positionNames,
              n,
            ),
          ],
        );

        return ListPageTemplate(
          activeFilters: _chips(filter, n),
          mainSearchFields: mainBlock,
          countText: '총 ${rows.length}명이 조회되었습니다.',
          onRefresh: () => ref.read(userProvider.notifier).refresh(),
          table: _UserTable(rows: rows),
          registerMenuCd: kMenuMst001,
          onRegister: () => context.push(AppRoutes.masterUsersRegister),
          extraHeaderActions: [
            OutlinedButton.icon(
              onPressed: () => _resetPasswords(rows),
              icon: const Icon(Icons.lock_reset_outlined, size: 18),
              label: const Text(
                '비밀번호 초기화',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadCsv(rows),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text(
                '일괄 다운로드',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _uploadCsv(users),
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text(
                '일괄 업로드',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 비밀번호를 초기값으로 되돌린다. 화면 검색·필터로 좁힌 [rows] 가 대상이다
  /// (체크박스 다중선택 UI가 아직 없어, 기존 검색/필터를 "선택" 수단으로
  /// 쓴다 — 특정 한 명만 바꾸려면 검색으로 그 사람만 남긴 뒤 누르면 된다).
  Future<void> _resetPasswords(List<User> rows) async {
    // 본인은 대상에서 뺀다. 서버는 초기화한 계정의 토큰을 전부 끊기 때문에,
    // 목록에 내가 섞여 있으면 내 차례가 오는 순간 내 토큰이 죽어 그 뒤 사원들이
    // 전부 401 로 실패하고 화면은 로그인으로 튕긴다 — 어디까지 초기화됐는지조차
    // 알 수 없게 된다. 내 비밀번호는 '내 정보'에서 직접 바꾸면 된다.
    final myUserId = context.read<AuthProvider>().userId.trim().toLowerCase();
    final withLoginId = rows.where((u) => u.userId.trim().isNotEmpty).toList();
    final eligible = myUserId.isEmpty
        ? withLoginId
        : withLoginId
              .where((u) => u.userId.trim().toLowerCase() != myUserId)
              .toList();
    final selfExcluded = withLoginId.length - eligible.length;

    if (eligible.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selfExcluded > 0
                ? '본인 계정만 조회되어 초기화할 대상이 없습니다.'
                : '로그인ID가 있는 사원이 없습니다.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ResetPasswordConfirmDialog(
        users: eligible,
        selfExcluded: selfExcluded,
      ),
    );
    if (confirmed != true) return;

    final api = ref.read(mst001ApiServiceProvider);
    final succeeded = <String>[];
    final failures = <String>[];
    for (final u in eligible) {
      final result = await api.resetPassword(u.userIdx);
      if (result.ok) {
        succeeded.add('${u.name}(${u.userId})');
      } else {
        failures.add('${u.name}(${u.userId}): ${result.failure}');
      }
    }

    if (!mounted) return;
    // 실패 목록을 debugPrint 로만 남기면 "누구까지 초기화됐는지" 알 방법이 없어
    // 복구 판단을 못 한다. 결과를 화면에 남긴다.
    if (failures.isEmpty) {
      await showAlertDialog(
        context,
        '${succeeded.length}명의 비밀번호를 초기 비밀번호로 되돌렸습니다.',
        title: '비밀번호 초기화 완료',
      );
      return;
    }
    // 공통 알림은 스크롤이 없어 줄이 많으면 넘친다 — 앞부분만 보여주고 나머지는 건수로.
    const maxLines = 15;
    final shown = failures.take(maxLines).join('\n');
    final rest = failures.length - maxLines;
    await showAlertDialog(
      context,
      '성공 ${succeeded.length}건 · 실패 ${failures.length}건\n\n'
      '[실패]\n$shown${rest > 0 ? '\n… 외 $rest건' : ''}',
      title: '비밀번호 초기화 결과',
    );
  }

  Future<void> _downloadCsv(List<User> rows) async {
    final csv = buildUsersCsv(rows);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    try {
      await FilePicker.platform.saveFile(
        dialogTitle: '사원 목록 다운로드',
        fileName: 'employees.csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('다운로드 실패: $e')));
    }
  }

  Future<void> _uploadCsv(List<User> allUsers) async {
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    final files = picked?.files ?? const [];
    if (files.isEmpty) return;
    final bytes = files.first.bytes;
    if (bytes == null) return;

    List<ParsedUserCsvRow> parsedRows;
    try {
      parsedRows = parseUsersCsv(utf8.decode(bytes, allowMalformed: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV를 읽지 못했습니다: $e')));
      return;
    }

    // 토큰번호(시스템 내부 고유 식별자)가 1순위 매칭 키다 — 로그인ID 자체를
    // 바꾸는 업로드도 지원해야 하기 때문이다(로그인ID로만 찾으면 "새 값"이
    // 기존 누구와도 일치하지 않아 항상 "못 찾음"이 된다). 토큰번호 컬럼이
    // 없는 예전 형식 파일은 지금까지처럼 로그인ID로 찾는다.
    final byUserIdx = {for (final u in allUsers) u.userIdx: u};
    final byUserId = {
      for (final u in allUsers)
        if (u.userId.trim().isNotEmpty) u.userId.trim(): u,
    };
    final deptIdxByName = await _deptIdxByName(allUsers);
    final positionCdByName = await _positionCdByName(allUsers);

    User? findExisting(ParsedUserCsvRow row) {
      if (row.userIdx != null) {
        final byIdx = byUserIdx[row.userIdx];
        if (byIdx != null) return byIdx;
      }
      return byUserId[row.userId];
    }

    // CSV에 적힌 값을 그대로 "이렇게 저장됩니다" 미리보기로 보여준다.
    // 기존 값과 비교하지 않는다 — 파일 내용 전체가 통째로 달라져도 그대로 반영.
    final plans = parsedRows.map((row) {
      final deptNm = row.department.trim();
      final positionNm = row.positionNm.trim();
      return _PlannedUserUpdate(
        userId: row.userId,
        existing: findExisting(row),
        name: row.name,
        department: row.department,
        deptIdx: deptIdxByName[deptNm],
        // 이름을 코드로 바꾸지 못하면 저장 때 기존 값이 유지된다. 그 사실을
        // 미리보기에서 알려야 하므로 "비어 있음"과 "못 찾음"을 구분해 둔다.
        deptResolved: deptNm.isEmpty || deptIdxByName.containsKey(deptNm),
        positionNm: row.positionNm,
        positionCd: positionCdByName[positionNm] ?? '',
        positionResolved:
            positionNm.isEmpty || positionCdByName.containsKey(positionNm),
        mobilePhone: row.mobilePhone,
        email: row.email,
        svYn: row.svYn,
      );
    }).toList();

    if (plans.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV에서 읽은 데이터가 없습니다.')),
      );
      return;
    }

    // 미리보기 다이얼로그 — 확인 눌러야 실제 저장이 진행된다.
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _UploadPreviewDialog(plans: plans),
    );
    if (confirmed != true) return;

    final api = ref.read(mst001ApiServiceProvider);
    var updated = 0;
    var notFound = 0;
    var failed = 0;
    var unmapped = 0;
    for (final plan in plans) {
      final existing = plan.existing;
      if (existing == null) {
        notFound++;
        continue;
      }
      if (plan.deptUnresolved || plan.positionUnresolved) unmapped++;
      try {
        final body = User.buildUpdateUserRequest(
          name: plan.name.isEmpty ? existing.name : plan.name,
          userId: plan.userId,
          deptIdx: plan.deptIdx ?? existing.deptIdx,
          mobilePhone: plan.mobilePhone,
          email: plan.email,
          // 직급 이름을 코드로 못 바꿨으면 기존 값을 그대로 둔다. 여기서 빈
          // 문자열을 보내면 서버가 "직급을 지워라"로 받아들인다(기존 값이 없으면
          // null 이 되어 키 자체가 빠진다 = 손대지 않음).
          positionCd: plan.positionCd.isEmpty
              ? existing.positionCd
              : plan.positionCd,
          // 입사일은 CSV가 다루지 않는 항목이라 넘기지 않는다 — 넘기면 지워진다.
          svYn: plan.svYn,
          ownerYn: existing.ownerYn == OwnerYn.yes,
        );
        await api.updateUser(existing.userIdx, body);
        // 목록 캐시만 갱신하면 상세화면은 예전 값을 계속 보여준다 —
        // 방금 수정한 사원의 상세 캐시도 같이 무효화해야 즉시 반영된다.
        ref.invalidate(userDetailProvider(existing.userIdx));
        updated++;
      } catch (e, st) {
        debugPrint('CSV 일괄 업로드 실패 (userIdx=${existing.userIdx}): $e\n$st');
        failed++;
      }
    }

    ref.read(userProvider.notifier).refresh();
    if (!mounted) return;
    // 이름을 코드로 못 바꾼 건은 저장은 됐지만 부서·직급만 예전 값 그대로다.
    // 예전에는 그걸 그냥 '수정 n건' 에 섞어 세어, 반영된 줄 알고 넘어가게 했다.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '일괄 업로드 완료 — 수정 $updated건'
          '${notFound > 0 ? ', 토큰번호·로그인ID 못 찾음 $notFound건' : ''}'
          '${unmapped > 0 ? ', 부서·직급 이름 못 찾아 기존값 유지 $unmapped건' : ''}'
          '${failed > 0 ? ', 실패 $failed건' : ''}',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// 부서명 → deptIdx.
  ///
  /// 부서 마스터(GET /dept/list)를 기준으로 만든다. 예전에는 "현재 사원 목록에
  /// 이미 등장하는 부서명"으로만 표를 만들어서, 소속 인원이 0명인 신설 부서로
  /// 옮기는 조직개편 CSV — 즉 이 기능의 가장 흔한 사용 시나리오 — 가 통째로
  /// 무시됐다(미리보기는 바뀐다고 파랗게 표시하는데 저장은 기존 값 그대로).
  /// 부서 목록 조회가 실패하면 예전 방식으로라도 매핑한다.
  Future<Map<String, int>> _deptIdxByName(List<User> allUsers) async {
    final byName = <String, int>{
      for (final u in allUsers)
        if (u.department.trim().isNotEmpty && u.deptIdx != null)
          u.department.trim(): u.deptIdx!,
    };
    final flat = <Department>[];
    _flattenDepartmentTree(await DepartmentRepository().all(), flat);
    for (final d in flat) {
      final name = d.name.trim();
      final idx = int.tryParse(d.id);
      if (name.isNotEmpty && idx != null) byName[name] = idx;
    }
    return byName;
  }

  /// 직급명 → positionCd. 근거는 공통코드(grp_cd=60)이며, 조회 실패 시에만
  /// 사원 목록에 등장한 직급으로 대체한다([_deptIdxByName]과 같은 이유).
  Future<Map<String, String>> _positionCdByName(List<User> allUsers) async {
    final byName = <String, String>{
      for (final u in allUsers)
        if (u.positionNm.trim().isNotEmpty && (u.positionCd ?? '').isNotEmpty)
          u.positionNm.trim(): u.positionCd!,
    };
    try {
      final codes = await CommonCodeApiService().getCodes(_kUserPositionGrpCd);
      for (final c in codes) {
        final name = c.codeNm.trim();
        if (name.isNotEmpty && c.codeCd.isNotEmpty) byName[name] = c.codeCd;
      }
    } catch (e) {
      debugPrint('직급 코드 조회 실패 — 사원 목록에 등장한 직급으로만 매핑: $e');
    }
    return byName;
  }

  List<ActiveFilterChip> _chips(UserFilter f, UserNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.userKeyword.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: ${f.userKeyword}',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setUserKeyword('');
            });
          },
        ),
      );
    }
    if (f.department != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '부서: ${f.department}',
          onClear: () => n.setDepartment('전체'),
        ),
      );
    }
    if (f.position != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '직급: ${f.position}',
          onClear: () => n.setPosition('전체'),
        ),
      );
    }
    return chips;
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({required this.rows});

  final List<User> rows;

  @override
  Widget build(BuildContext context) {
    return ErpVirtualDataTable(
      minWidth: AppDimensions.tableMinWidthStandard,
      columnWidths: const {
        0: FixedColumnWidth(90),
        1: FlexColumnWidth(0.8),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(140),
        4: FlexColumnWidth(1.0),
        5: FlexColumnWidth(1.2),
        6: FixedColumnWidth(90),
      },
      headerRow: const TableRow(
        decoration: kErpTableHeaderRowDecoration,
        children: [
          ErpTableHeaderCell('이름'),
          ErpTableHeaderCell('부서'),
          ErpTableHeaderCell('직급'),
          ErpTableHeaderCell('휴대전화'),
          ErpTableHeaderCell('로그인ID'),
          ErpTableHeaderCell('이메일 주소'),
          ErpTableHeaderCell('태그사용여부 '),
        ],
      ),
      rowCount: rows.length,
      rowBuilder: (rowContext, index) {
        final user = rows[index];
        void openDetail() => rowContext.goNamed(
          AppRouteNames.masterUserDetail,
          pathParameters: {'userIdx': '${user.userIdx}'},
        );
        Widget tap(Widget child) =>
            ErpTableDoubleTapCell(onDoubleTap: openDetail, child: child);
        return TableRow(
          decoration: BoxDecoration(
            color: index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
          ),
          children: [
            tap(ErpTableBodyCell(user.name, center: true)),
            tap(
              ErpTableBodyCell(
                user.department.isEmpty ? '-' : user.department,
                center: true,
              ),
            ),
            tap(
              ErpTableBodyCell(
                user.positionNm.isEmpty ? '-' : user.positionNm,
                center: true,
              ),
            ),
            tap(
              ErpTableBodyCell(
                formatKoreanPhoneDisplay(user.mobilePhone),
                center: true,
              ),
            ),
            tap(ErpTableBodyCell(user.userId, center: true)),
            tap(ErpTableBodyCell(user.email, center: true)),
            tap(_YnFieldChip(active: user.svYn == SvYn.yes)),
          ],
        );
      },
    );
  }
}

/// 읽기 전용 — Y/N 여부를 칩 형태로 표시한다.
class _YnFieldChip extends StatelessWidget {
  const _YnFieldChip({required this.active});

  final bool active;

  static const String activeLabel = '사  용';
  static const String inactiveLabel = '미사용';

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.statusRenewal : AppTheme.textMuted;
    final label = active ? activeLabel : inactiveLabel;

    return Align(
      alignment: Alignment.center,
      child: StatusBadge(label, color: color, showDot: false),
    );
  }
}

/// "비밀번호 초기화" 실행 전 확인 — 대상자 명단과 결과를 미리 보여준다.
class _ResetPasswordConfirmDialog extends StatelessWidget {
  const _ResetPasswordConfirmDialog({
    required this.users,
    this.selfExcluded = 0,
  });

  final List<User> users;

  /// 대상에서 제외된 본인 계정 수(0 또는 1). 왜 명단에 내가 없는지 알려 준다.
  final int selfExcluded;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('비밀번호 초기화'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아래 ${users.length}명의 비밀번호를 초기 비밀번호로 되돌립니다.\n'
              '기존 로그인 세션은 끊어지고, 다음 로그인 시 비밀번호 변경이 필요합니다.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            if (selfExcluded > 0) ...[
              const SizedBox(height: 4),
              const Text(
                '※ 본인 계정은 제외했습니다 — 초기화하는 순간 내 세션이 끊겨 '
                '나머지 사원이 전부 실패합니다. 내 비밀번호는 [내 정보]에서 바꾸세요.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusPending,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (listContext, index) {
                      final u = users[index];
                      return Text('${u.name} (${u.userId})');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
          child: Text('${users.length}명 초기화'),
        ),
      ],
    );
  }
}

/// CSV 한 행을 실제로 반영했을 때의 결과 — 미리보기·저장에 공통으로 쓴다.
/// CSV 한 행이 저장될 최종 값 — 기존 값과 비교하지 않고 그대로 보여준다.
class _PlannedUserUpdate {
  const _PlannedUserUpdate({
    required this.userId,
    required this.existing,
    required this.name,
    required this.department,
    required this.deptIdx,
    required this.deptResolved,
    required this.positionNm,
    required this.positionCd,
    required this.positionResolved,
    required this.mobilePhone,
    required this.email,
    required this.svYn,
  });

  final String userId;

  /// 이 로그인ID와 일치하는 기존 사원. null 이면 반영 대상에서 제외된다.
  final User? existing;
  final String name;
  final String department;
  final int? deptIdx;

  /// CSV의 부서명을 실제 deptIdx로 바꿀 수 있었는지. 못 바꾸면 저장 시 기존
  /// 부서가 유지되므로 "바뀜"으로 표시하면 안 된다(가장 흔한 오해의 원인).
  final bool deptResolved;
  final String positionNm;
  final String positionCd;

  /// 직급명 → positionCd 변환 성공 여부. [deptResolved]와 같은 이유.
  final bool positionResolved;
  final String mobilePhone;
  final String email;
  final bool svYn;

  bool get matched => existing != null;

  /// 매칭은 됐는데 이름을 코드로 못 바꾼 상태 — 저장해도 그 칸만 안 바뀐다.
  bool get deptUnresolved => matched && !deptResolved;

  bool get positionUnresolved => matched && !positionResolved;

  /// 기존 값과 실제로 달라지는 필드 — 판정 로직은 [diffUserCsvRow](단위테스트 있음)와 공유한다.
  UserCsvRowDiff? get _diff => existing == null
      ? null
      : diffUserCsvRow(
          ParsedUserCsvRow(
            name: name,
            department: department,
            positionNm: positionNm,
            mobilePhone: mobilePhone,
            userId: userId,
            email: email,
            svYn: svYn,
          ),
          existing!,
        );

  bool get userIdChanged => _diff?.userIdChanged ?? false;
  bool get nameChanged => _diff?.nameChanged ?? false;

  /// 부서·직급은 이름을 코드로 바꿔야 저장된다 — 못 바꾼 행은 실제로 아무것도
  /// 안 바뀌므로 "바뀜"에서 뺀다(빼지 않으면 미리보기가 거짓말을 한다).
  bool get departmentChanged =>
      deptResolved && (_diff?.departmentChanged ?? false);
  bool get positionChanged =>
      positionResolved && (_diff?.positionChanged ?? false);
  bool get phoneChanged => _diff?.phoneChanged ?? false;
  bool get emailChanged => _diff?.emailChanged ?? false;
  bool get svYnChanged => _diff?.svYnChanged ?? false;

  bool get hasAnyChange =>
      userIdChanged ||
      nameChanged ||
      departmentChanged ||
      positionChanged ||
      phoneChanged ||
      emailChanged ||
      svYnChanged;
}

/// CSV 업로드 전 — "데이터가 이렇게 저장됩니다"를 그대로 보여주고 승인받는 다이얼로그.
/// 기존 값과의 비교(diff)는 하지 않는다 — 파일 전체가 통째로 달라져도 상관없다.
///
/// 화면 크기에 맞춰 반응형으로 커지고, 가로·세로 스크롤바를 항상 보이게
/// 둔다 — 고정 크기(720×420)였을 때 오른쪽 컬럼이 안 보이는데 스크롤
/// 가능하다는 표시조차 없어 "화면이 잘렸다"는 신고로 이어졌다.
class _UploadPreviewDialog extends StatefulWidget {
  const _UploadPreviewDialog({required this.plans});

  final List<_PlannedUserUpdate> plans;

  @override
  State<_UploadPreviewDialog> createState() => _UploadPreviewDialogState();
}

class _UploadPreviewDialogState extends State<_UploadPreviewDialog> {
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;
    final matchedCount = plans.where((p) => p.matched).length;
    final notFoundCount = plans.length - matchedCount;
    final changedCount = plans.where((p) => p.hasAnyChange).length;
    final unmappedCount = plans
        .where((p) => p.deptUnresolved || p.positionUnresolved)
        .length;
    final duplicateIds = findDuplicateTargetUserIds(
      plans.where((p) => p.matched).map((p) => p.userId),
    );

    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = (screen.width * 0.92).clamp(480.0, 1180.0);
    final tableMaxHeight = (screen.height * 0.6).clamp(240.0, 560.0);

    return AlertDialog(
      title: const Text('업로드 내용 확인'),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSV ${plans.length}행 · 저장 대상 $matchedCount명'
              '${notFoundCount > 0 ? ' · 토큰번호·로그인ID 못 찾아 제외 $notFoundCount건' : ''}'
              ' — 아래 데이터 그대로 저장됩니다.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // 전체 목록을 그대로 재업로드하면 대부분 행이 기존과 동일하다 —
              // 실제로 바뀌는 값이 몇 건인지 보여줘야 업로드가 헛되지 않았음을 알 수 있다.
              changedCount > 0
                  ? '실제로 값이 바뀌는 항목 $changedCount건 (파란 글씨) · 기존과 동일 ${matchedCount - changedCount}건'
                  : '기존 값과 달라지는 항목이 없습니다 — 저장해도 변화가 없습니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: changedCount > 0
                    ? AppTheme.statusRenewal
                    : AppTheme.statusPending,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            if (unmappedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                // 부서·직급은 이름이 아니라 코드로 저장된다. 등록되지 않은
                // 이름이 적혀 있으면 그 칸만 조용히 기존 값으로 남는데, 예전에는
                // 그걸 파란 글씨로 "바뀜"이라 표시해 반영된 줄 알게 만들었다.
                '⚠ 등록되지 않은 부서·직급 이름 $unmappedCount건 — 해당 칸은 기존 값이 그대로 유지됩니다. '
                '부서관리에서 부서를 먼저 만들거나 이름 표기를 맞춰 주세요.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusPending,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ],
            if (duplicateIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                // 로그인ID는 서버에서 유일해야 한다 — 같은 값을 목표로 하는
                // 행이 여럿이면 하나만 저장되고 나머지는 실패한다. 저장을
                // 누르기 전에 미리 알려준다(막지는 않는다 — 우연히 한쪽만
                // 원하는 경우도 있을 수 있어서).
                '⚠ 같은 로그인ID가 여러 명에게 지정됨: ${duplicateIds.join(', ')} '
                '— 하나만 저장되고 나머지는 실패합니다.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusPending,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: tableMaxHeight),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 40,
                          columns: const [
                            DataColumn(label: Text('이름')),
                            DataColumn(label: Text('부서')),
                            DataColumn(label: Text('직급')),
                            DataColumn(label: Text('휴대전화')),
                            DataColumn(label: Text('로그인ID')),
                            DataColumn(label: Text('이메일 주소')),
                            DataColumn(label: Text('태그사용여부')),
                          ],
                          rows: [
                            for (final p in plans)
                              DataRow(
                                color: p.matched
                                    ? null
                                    : WidgetStatePropertyAll(
                                        AppTheme.statusPending.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                cells: [
                                  DataCell(
                                    _diffText(
                                      p.name.isEmpty ? '-' : p.name,
                                      p.nameChanged,
                                    ),
                                  ),
                                  DataCell(
                                    _mappedNameCell(
                                      p.department,
                                      changed: p.departmentChanged,
                                      unresolved: p.deptUnresolved,
                                    ),
                                  ),
                                  DataCell(
                                    _mappedNameCell(
                                      p.positionNm,
                                      changed: p.positionChanged,
                                      unresolved: p.positionUnresolved,
                                    ),
                                  ),
                                  DataCell(
                                    _diffText(
                                      p.mobilePhone.isEmpty
                                          ? '-'
                                          : p.mobilePhone,
                                      p.phoneChanged,
                                    ),
                                  ),
                                  DataCell(_userIdCell(p)),
                                  DataCell(
                                    _diffText(
                                      p.email.isEmpty ? '-' : p.email,
                                      p.emailChanged,
                                    ),
                                  ),
                                  DataCell(
                                    _diffText(
                                      p.svYn ? '사용' : '미사용',
                                      p.svYnChanged,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: matchedCount == 0
              ? null
              : () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
          child: Text('$matchedCount명 이대로 저장'),
        ),
      ],
    );
  }

  /// 기존 값과 달라지는 셀만 파란 글씨로 강조한다. 강조가 없으면 CSV를
  /// 재업로드해도 사원관리 목록을 그대로 다시 보여주는 것과 구분이 안 된다.
  Widget _diffText(String text, bool changed) {
    return Text(
      text,
      style: changed
          ? const TextStyle(
              color: AppTheme.statusRenewal,
              fontWeight: FontWeight.w700,
            )
          : null,
    );
  }

  /// 부서·직급 칸. 이름을 코드로 못 바꾼 행은 파란 글씨(=바뀜) 대신 경고색으로
  /// 사유를 붙여 보여준다 — 그대로 저장해도 그 칸만 안 바뀌기 때문이다.
  Widget _mappedNameCell(
    String text, {
    required bool changed,
    required bool unresolved,
  }) {
    final shown = text.trim().isEmpty ? '-' : text.trim();
    if (unresolved) {
      return Text(
        '$shown (등록된 이름 아님 · 기존값 유지)',
        style: const TextStyle(
          color: AppTheme.statusPending,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return _diffText(shown, changed);
  }

  /// 로그인ID가 바뀌는 행은 "기존ID → 새ID" 형태로 보여준다. 토큰번호 매칭
  /// 덕분에 로그인ID 자체를 바꾸는 업로드도 가능해졌으니, 무엇이 무엇으로
  /// 바뀌는지 이 칸에서 바로 확인할 수 있어야 한다.
  Widget _userIdCell(_PlannedUserUpdate p) {
    if (!p.matched) {
      return Text(
        '${p.userId} (못 찾음)',
        style: const TextStyle(
          color: AppTheme.statusPending,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (!p.userIdChanged) {
      return Text(p.userId);
    }
    return Text(
      '${p.existing!.userId} → ${p.userId}',
      style: const TextStyle(
        color: AppTheme.statusRenewal,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
