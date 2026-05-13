// user_mst(`/users`) 사원 목록에서 한 명을 고르는 조회 다이얼로그.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

/// 성명·부서·직급·연락처로 필터해 [User](user_mst) 한 명을 고른다.
class UserLookupDialog extends StatefulWidget {
  const UserLookupDialog({
    super.key,
    required this.usersFuture,
    this.initialSearchKeyword,
  });

  final Future<List<User>> usersFuture;

  /// 다이얼로그 상단 검색란에 미리 채울 문자열(예: 조사자 필드에서 Enter).
  final String? initialSearchKeyword;

  @override
  State<UserLookupDialog> createState() => _UserLookupDialogState();
}

class _UserLookupDialogState extends State<UserLookupDialog> {
  final _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final seed = widget.initialSearchKeyword?.trim();
    if (seed != null && seed.isNotEmpty) {
      _keywordController.text = seed;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<User> _filter(List<User> rows) {
    final q = _keywordController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.department.toLowerCase().contains(q) ||
          e.positionNm.toLowerCase().contains(q) ||
          e.mobilePhone.toLowerCase().contains(q) ||
          e.userId.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ErpDialogFrame(
        title: '사원 조회',
        maxWidth: 820,
        maxHeight: 620,
        child: SizedBox(
          height: 500,
          child: FutureBuilder<List<User>>(
            future: widget.usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CommonLoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '사원 목록을 불러오지 못했습니다.',
                    style: FormStylePalette.valueStyle,
                  ),
                );
              }

              final users = _filter(snapshot.data ?? const <User>[]);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _keywordController,
                    onChanged: (_) => setState(() {}),
                    style: FormStylePalette.valueStyle,
                    decoration: _userLookupSearchDecoration(
                      '성명, 부서, 직급, 연락처, 아이디 검색',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _UserLookupHeader(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: users.isEmpty
                        ? Center(
                            child: Text(
                              '조회된 사원이 없습니다.',
                              style: FormStylePalette.valueStyle,
                            ),
                          )
                        : ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xFFE5E7EB),
                            ),
                            itemBuilder: (context, index) {
                              return _UserLookupRow(
                                stripeIndex: index,
                                displayNo: index + 1,
                                user: users[index],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UserLookupHeader extends StatelessWidget {
  const _UserLookupHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: FormStylePalette.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          SizedBox(width: 56, child: _UserLookupHeaderText('NO')),
          Expanded(flex: 1, child: _UserLookupHeaderText('성명')),
          Expanded(flex: 1, child: _UserLookupHeaderText('부서')),
          Expanded(flex: 1, child: _UserLookupHeaderText('직급')),
          Expanded(flex: 2, child: _UserLookupHeaderText('아이디')),
        ],
      ),
    );
  }
}

class _UserLookupHeaderText extends StatelessWidget {
  const _UserLookupHeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }
}

class _UserLookupRow extends StatelessWidget {
  const _UserLookupRow({
    required this.stripeIndex,
    required this.displayNo,
    required this.user,
  });

  final int stripeIndex;
  final int displayNo;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: erpPopupListRowBackground(stripeIndex),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 56, child: _UserLookupCell('$displayNo')),
              Expanded(flex: 1, child: _UserLookupCell(user.name)),
              Expanded(
                flex: 1,
                child: _UserLookupCell(user.department),
              ),
              Expanded(
                flex: 1,
                child: _UserLookupCell(user.positionNm),
              ),
              Expanded(flex: 2, child: _UserLookupCell(user.userId)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserLookupCell extends StatelessWidget {
  const _UserLookupCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.isEmpty ? '-' : text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: FormStylePalette.valueStyle,
    );
  }
}

InputDecoration _userLookupSearchDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: FormStylePalette.textMuted,
      fontSize: 13,
      fontFamilyFallback: AppTheme.koreanFontFallback,
    ),
    isDense: true,
    filled: true,
    fillColor: FormStylePalette.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    prefixIcon: const Icon(
      Icons.search_rounded,
      size: 20,
      color: FormStylePalette.textSecondary,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
    ),
  );
}
