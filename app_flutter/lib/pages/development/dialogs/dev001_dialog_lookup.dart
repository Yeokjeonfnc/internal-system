// 예비창업자 목록에서 선택하는 조회 다이얼로그(가맹점·물건 등 공통).



import 'package:flutter/material.dart';



import 'package:app_flutter/core/format/korean_phone_display.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';

import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';

import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';

import 'package:app_flutter/core/widgets/common/erp_lookup_dialog.dart';

import 'package:app_flutter/pages/development/dev001/dev001_model.dart';



/// 성명·연락처·상태로 필터해 [Partner] 한 명을 고른다.

class PartnerLookupDialog extends StatefulWidget {

  const PartnerLookupDialog({

    super.key,

    required this.partnersFuture,

    this.initialSearchKeyword,

  });



  final Future<List<Partner>> partnersFuture;

  final String? initialSearchKeyword;

  @override

  State<PartnerLookupDialog> createState() => _PartnerLookupDialogState();

}



class _PartnerLookupDialogState extends State<PartnerLookupDialog> {

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



  List<Partner> _match(List<Partner> rows) {

    final q = _keywordController.text.trim().toLowerCase();

    if (q.isEmpty) return rows;

    return rows.where((partner) {

      final status = statusLabelKo(partner.partnerStatus);

      return partner.partnerNm.toLowerCase().contains(q) ||

          partner.partnerTel.toLowerCase().contains(q) ||

          status.toLowerCase().contains(q);

    }).toList();

  }



  @override

  Widget build(BuildContext context) {

    return Dialog(

      backgroundColor: Colors.transparent,

      insetPadding: erpLookupDialogInset(context),

      child: ErpDialogFrame(

        title: '예비창업자 조회',

        maxWidth: 760,

        maxHeight: 620,

        child: SizedBox(

          height: 500,

          child: FutureBuilder<List<Partner>>(

            future: widget.partnersFuture,

            builder: (context, snapshot) {

              if (snapshot.connectionState != ConnectionState.done) {

                return const CommonLoadingIndicator();

              }

              if (snapshot.hasError) {

                return Center(

                  child: Text(

                    '예비창업자 목록을 불러오지 못했습니다.',

                    style: FormStylePalette.valueStyle,

                  ),

                );

              }



              final partners = _match(snapshot.data ?? const <Partner>[]);



              return Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  TextField(

                    controller: _keywordController,

                    onChanged: (_) => setState(() {}),

                    style: FormStylePalette.valueStyle,

                    decoration: erpLookupSearchDecoration('성명, 휴대전화, 상태 검색'),

                  ),

                  const SizedBox(height: 12),

                  ErpLookupHeaderBar(

                    minTableWidth: kErpLookupTableMinWidthPartner,

                    children: const [

                      SizedBox(

                        width: kErpLookupNoWidth,

                        child: ErpLookupHeaderText('NO'),

                      ),

                      Expanded(child: ErpLookupHeaderText('성명')),

                      SizedBox(

                        width: kErpLookupTelWidth,

                        child: ErpLookupHeaderText('휴대전화'),

                      ),

                      Expanded(child: ErpLookupHeaderText('상태')),

                    ],

                  ),

                  const SizedBox(height: 6),

                  Expanded(

                    child: partners.isEmpty

                        ? Center(

                            child: Text(

                              '조회된 예비창업자가 없습니다.',

                              style: FormStylePalette.valueStyle,

                            ),

                          )

                        : ListView.separated(

                            itemCount: partners.length,

                            separatorBuilder: (_, _) => const Divider(

                              height: 1,

                              color: Color(0xFFE5E7EB),

                            ),

                            itemBuilder: (context, index) {

                              final partner = partners[index];

                              return ErpLookupListRow(

                                stripeIndex: index,

                                minTableWidth: kErpLookupTableMinWidthPartner,

                                onTap: () => Navigator.of(context).pop(partner),

                                children: [

                                  SizedBox(

                                    width: kErpLookupNoWidth,

                                    child: ErpLookupBodyText('${index + 1}'),

                                  ),

                                  Expanded(

                                    child: ErpLookupBodyText(partner.partnerNm),

                                  ),

                                  SizedBox(

                                    width: kErpLookupTelWidth,

                                    child: ErpLookupBodyText(

                                      formatKoreanPhoneDisplay(partner.partnerTel),

                                    ),

                                  ),

                                  Expanded(

                                    child: ErpLookupBodyText(

                                      statusLabelKo(partner.partnerStatus),

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

              );

            },

          ),

        ),

      ),

    );

  }

}

