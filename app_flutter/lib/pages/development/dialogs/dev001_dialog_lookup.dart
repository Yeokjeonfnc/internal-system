// 예비창업자 목록에서 선택하는 조회 다이얼로그(가맹점·물건 등 공통).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
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
      insetPadding: const EdgeInsets.all(28),
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
                    decoration: _searchDecor('성명, 휴대전화, 상태 검색'),
                  ),
                  const SizedBox(height: 12),
                  const _PartnerLookupHeader(),
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
                              return _PartnerLookupRow(
                                stripeIndex: index,
                                displayNo: index + 1,
                                partner: partners[index],
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

class _PartnerLookupHeader extends StatelessWidget {
  const _PartnerLookupHeader();

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
          SizedBox(width: 70, child: _PartnerLookupHeaderText('NO')),
          Expanded(flex: 2, child: _PartnerLookupHeaderText('성명')),
          Expanded(flex: 2, child: _PartnerLookupHeaderText('휴대전화')),
          Expanded(flex: 2, child: _PartnerLookupHeaderText('상태')),
        ],
      ),
    );
  }
}

class _PartnerLookupHeaderText extends StatelessWidget {
  const _PartnerLookupHeaderText(this.text);

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

class _PartnerLookupRow extends StatelessWidget {
  const _PartnerLookupRow({
    required this.stripeIndex,
    required this.displayNo,
    required this.partner,
  });

  final int stripeIndex;
  final int displayNo;
  final Partner partner;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: erpPopupListRowBackground(stripeIndex),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(partner),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 70, child: _PartnerLookupCell('$displayNo')),
              Expanded(flex: 2, child: _PartnerLookupCell(partner.partnerNm)),
              Expanded(
                flex: 2,
                child: _PartnerLookupCell(_telFmt(partner.partnerTel)),
              ),
              Expanded(
                flex: 2,
                child: _PartnerLookupCell(statusLabelKo(partner.partnerStatus)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerLookupCell extends StatelessWidget {
  const _PartnerLookupCell(this.text);

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

InputDecoration _searchDecor(String hint) {
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

String _telFmt(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';

  if (digits.startsWith('02')) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 2)}-${digits.substring(2)}';
    }
    if (digits.length <= 9) {
      return '${digits.substring(0, 2)}-${digits.substring(2, digits.length - 4)}-${digits.substring(digits.length - 4)}';
    }
    final clipped = digits.substring(0, 10);
    return '${clipped.substring(0, 2)}-${clipped.substring(2, 6)}-${clipped.substring(6)}';
  }

  final clipped = digits.length > 11 ? digits.substring(0, 11) : digits;
  if (clipped.length <= 3) return clipped;
  if (clipped.length <= 7) {
    return '${clipped.substring(0, 3)}-${clipped.substring(3)}';
  }
  return '${clipped.substring(0, 3)}-${clipped.substring(3, clipped.length - 4)}-${clipped.substring(clipped.length - 4)}';
}
