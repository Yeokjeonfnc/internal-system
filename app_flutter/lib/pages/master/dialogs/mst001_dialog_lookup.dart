// user_mst(`/users`) 사원 목록에서 한 명을 고르는 조회 다이얼로그.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/erp_lookup_dialog.dart';
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
      insetPadding: erpLookupDialogInset(context),
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

              return ErpLookupHorizontalSyncScope(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  TextField(
                    controller: _keywordController,
                    onChanged: (_) => setState(() {}),
                    style: FormStylePalette.valueStyle,
                    decoration: erpLookupSearchDecoration(
                      '성명, 부서, 직급, 연락처, 아이디 검색',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ErpLookupHeaderBar(
                    minTableWidth: kErpLookupTableMinWidthUser,
                    children: const [
                      SizedBox(
                        width: kErpLookupNoWidth,
                        child: ErpLookupHeaderText('NO'),
                      ),
                      SizedBox(
                        width: 88,
                        child: ErpLookupHeaderText('성명'),
                      ),
                      SizedBox(
                        width: 80,
                        child: ErpLookupHeaderText('부서'),
                      ),
                      SizedBox(
                        width: 72,
                        child: ErpLookupHeaderText('직급'),
                      ),
                      Expanded(child: ErpLookupHeaderText('아이디')),
                    ],
                  ),
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
                              final user = users[index];
                              return ErpLookupListRow(
                                stripeIndex: index,
                                minTableWidth: kErpLookupTableMinWidthUser,
                                onTap: () => Navigator.of(context).pop(user),
                                children: [
                                  SizedBox(
                                    width: kErpLookupNoWidth,
                                    child: ErpLookupBodyText('${index + 1}'),
                                  ),
                                  SizedBox(
                                    width: 88,
                                    child: ErpLookupBodyText(user.name),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: ErpLookupBodyText(user.department),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: ErpLookupBodyText(user.positionNm),
                                  ),
                                  Expanded(
                                    child: ErpLookupBodyText(user.userId),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  erpLookupDialogCloseFooter(context),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
