// 활동 등록 — 가맹점 선택 조회 다이얼로그.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/erp_lookup_dialog.dart';
import 'package:app_flutter/pages/franchise/str001/str001_api.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 키워드로 필터해 [Store] 한 건을 고른다.
class StoreLookupDialog extends StatefulWidget {
  const StoreLookupDialog({super.key});

  @override
  State<StoreLookupDialog> createState() => _StoreLookupDialogState();
}

class _StoreLookupDialogState extends State<StoreLookupDialog> {
  final _keywordController = TextEditingController();
  late Future<List<Store>> _storesFuture;

  @override
  void initState() {
    super.initState();
    _storesFuture = StoreApiService().getAllStores();
    _keywordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Store> _matchStores(List<Store> rows) {
    final q = _keywordController.text.trim();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (s) =>
              s.storeNm.contains(q) ||
              s.storeCd.contains(q) ||
              s.brandNm.contains(q) ||
              s.ownerNm.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: erpLookupDialogInset(context),
      child: ErpDialogFrame(
        title: '가맹점 검색',
        maxWidth: 980,
        maxHeight: 680,
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _keywordController,
                style: FormStylePalette.valueStyle,
                decoration: erpLookupSearchDecoration('키워드 검색'),
              ),
              const SizedBox(height: 12),
              ErpLookupHeaderBar(
                minTableWidth: kErpLookupTableMinWidthStore,
                children: const [
                  SizedBox(
                    width: kErpLookupNoWidth,
                    child: ErpLookupHeaderText('NO'),
                  ),
                  Expanded(child: ErpLookupHeaderText('가맹점명')),
                  SizedBox(
                    width: kErpLookupStoreBrandWidth,
                    child: ErpLookupHeaderText('브랜드'),
                  ),
                  SizedBox(
                    width: kErpLookupStoreCodeWidth,
                    child: ErpLookupHeaderText('가맹점코드'),
                  ),
                  SizedBox(
                    width: kErpLookupStoreOwnerWidth,
                    child: ErpLookupHeaderText('사업자명'),
                  ),
                  SizedBox(
                    width: kErpLookupStoreSvWidth,
                    child: ErpLookupHeaderText('담당수퍼바이저'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: FutureBuilder<List<Store>>(
                  future: _storesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CommonLoadingIndicator();
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '가맹점 목록을 불러오지 못했습니다.',
                          style: FormStylePalette.valueStyle,
                        ),
                      );
                    }

                    final rows = _matchStores(snapshot.data ?? const <Store>[]);
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          '검색 결과가 없습니다.',
                          style: FormStylePalette.valueStyle,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      itemBuilder: (context, index) {
                        final store = rows[index];
                        return ErpLookupListRow(
                          stripeIndex: index,
                          minTableWidth: kErpLookupTableMinWidthStore,
                          onTap: () => Navigator.of(context).pop(store),
                          children: [
                            SizedBox(
                              width: kErpLookupNoWidth,
                              child: ErpLookupBodyText('${index + 1}'),
                            ),
                            Expanded(
                              child: ErpLookupBodyText(
                                store.storeNm,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(
                              width: kErpLookupStoreBrandWidth,
                              child: ErpLookupBodyText(store.brandNm),
                            ),
                            SizedBox(
                              width: kErpLookupStoreCodeWidth,
                              child: ErpLookupBodyText(store.storeCd),
                            ),
                            SizedBox(
                              width: kErpLookupStoreOwnerWidth,
                              child: ErpLookupBodyText(store.ownerNm),
                            ),
                            SizedBox(
                              width: kErpLookupStoreSvWidth,
                              child: ErpLookupBodyText(store.svNm),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              erpLookupDialogCloseFooter(context),
            ],
          ),
        ),
      ),
    );
  }
}
