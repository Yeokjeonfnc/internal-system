// 가맹점 상세 — 물건 선택 조회 다이얼로그.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/erp_lookup_dialog.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';

String propertyLookupFormatWon(int value) {
  if (value == 0) return '-';
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

/// 물건명·주소·금액으로 필터해 [Property] 한 건을 고른다.
class PropertyLookupDialog extends StatefulWidget {
  const PropertyLookupDialog({super.key, required this.propertiesFuture});

  final Future<List<Property>> propertiesFuture;

  @override
  State<PropertyLookupDialog> createState() => _PropertyLookupDialogState();
}

class _PropertyLookupDialogState extends State<PropertyLookupDialog> {
  final _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Property> _filter(List<Property> rows) {
    final q = _keywordController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((property) {
      final address = _propertyAddress(property);
      return property.name.toLowerCase().contains(q) ||
          address.toLowerCase().contains(q) ||
          property.propIdx.toString().contains(q);
    }).toList();
  }

  String _propertyAddress(Property property) {
    final detail = property.addressDetail.trim();
    if (detail.isEmpty) return property.address;
    return '${property.address} $detail';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: erpLookupDialogInset(context),
      child: ErpDialogFrame(
        title: '물건 상세정보 조회',
        maxWidth: 1000,
        maxHeight: 640,
        child: SizedBox(
          height: 520,
          child: FutureBuilder<List<Property>>(
            future: widget.propertiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CommonLoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '물건 목록을 불러오지 못했습니다.',
                    style: FormStylePalette.valueStyle,
                  ),
                );
              }

              final properties = _filter(snapshot.data ?? const <Property>[]);

              return ErpLookupHorizontalSyncScope(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  TextField(
                    controller: _keywordController,
                    onChanged: (_) => setState(() {}),
                    style: FormStylePalette.valueStyle,
                    decoration: erpLookupSearchDecoration('물건명, 주소, 번호 검색'),
                  ),
                  const SizedBox(height: 12),
                  ErpLookupHeaderBar(
                    minTableWidth: kErpLookupTableMinWidthProperty,
                    children: const [
                      SizedBox(
                        width: kErpLookupNoWidth,
                        child: ErpLookupHeaderText('NO'),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: kErpLookupPropertyNameWidth,
                        child: ErpLookupHeaderText('물건명'),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: kErpLookupPropertyAddressWidth,
                        child: ErpLookupHeaderText('주소'),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: kErpLookupMoneyColWidth,
                        child: ErpLookupHeaderText('보증금'),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: kErpLookupMoneyColWidth,
                        child: ErpLookupHeaderText('임차료'),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: kErpLookupMoneyColWidth,
                        child: ErpLookupHeaderText('권리금'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: properties.isEmpty
                        ? Center(
                            child: Text(
                              '조회된 물건이 없습니다.',
                              style: FormStylePalette.valueStyle,
                            ),
                          )
                        : ListView.separated(
                            itemCount: properties.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xFFE5E7EB),
                            ),
                            itemBuilder: (context, index) {
                              final property = properties[index];
                              final address = _propertyAddress(property);
                              return ErpLookupListRow(
                                stripeIndex: index,
                                minTableWidth: kErpLookupTableMinWidthProperty,
                                onTap: () =>
                                    Navigator.of(context).pop(property),
                                children: [
                                  SizedBox(
                                    width: kErpLookupNoWidth,
                                    child: ErpLookupBodyText('${index + 1}'),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: kErpLookupPropertyNameWidth,
                                    child: ErpLookupBodyText(property.name),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: kErpLookupPropertyAddressWidth,
                                    child: ErpLookupBodyText(address),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: kErpLookupMoneyColWidth,
                                    child: ErpLookupBodyText(
                                      propertyLookupFormatWon(property.deposit),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: kErpLookupMoneyColWidth,
                                    child: ErpLookupBodyText(
                                      propertyLookupFormatWon(property.rent),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: kErpLookupMoneyColWidth,
                                    child: ErpLookupBodyText(
                                      propertyLookupFormatWon(
                                        property.keyMoney,
                                      ),
                                    ),
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
