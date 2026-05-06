// user_mst(`/users`) 사원 목록에서 한 명을 고르는 조회 다이얼로그.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/features/master/employee_model.dart';

/// 성명·부서·직급·연락처로 필터해 [Employee](user_mst) 한 명을 고른다.
class EmployeeLookupDialog extends StatefulWidget {
  const EmployeeLookupDialog({super.key, required this.employeesFuture});

  final Future<List<Employee>> employeesFuture;

  @override
  State<EmployeeLookupDialog> createState() => _EmployeeLookupDialogState();
}

class _EmployeeLookupDialogState extends State<EmployeeLookupDialog> {
  final _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Employee> _filter(List<Employee> rows) {
    final q = _keywordController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.department.toLowerCase().contains(q) ||
          e.jobTitle.toLowerCase().contains(q) ||
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
          child: FutureBuilder<List<Employee>>(
            future: widget.employeesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '사원 목록을 불러오지 못했습니다.',
                    style: FormStylePalette.valueStyle,
                  ),
                );
              }

              final employees = _filter(snapshot.data ?? const <Employee>[]);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _keywordController,
                    onChanged: (_) => setState(() {}),
                    style: FormStylePalette.valueStyle,
                    decoration: _employeeLookupSearchDecoration(
                      '성명, 부서, 직급, 연락처, 아이디 검색',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _EmployeeLookupHeader(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: employees.isEmpty
                        ? Center(
                            child: Text(
                              '조회된 사원이 없습니다.',
                              style: FormStylePalette.valueStyle,
                            ),
                          )
                        : ListView.separated(
                            itemCount: employees.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xFFE5E7EB),
                            ),
                            itemBuilder: (context, index) {
                              return _EmployeeLookupRow(
                                stripeIndex: index,
                                displayNo: index + 1,
                                employee: employees[index],
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

class _EmployeeLookupHeader extends StatelessWidget {
  const _EmployeeLookupHeader();

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
          SizedBox(width: 56, child: _EmployeeLookupHeaderText('NO')),
          Expanded(flex: 1, child: _EmployeeLookupHeaderText('성명')),
          Expanded(flex: 1, child: _EmployeeLookupHeaderText('부서')),
          Expanded(flex: 1, child: _EmployeeLookupHeaderText('직급')),
          Expanded(flex: 2, child: _EmployeeLookupHeaderText('아이디')),
        ],
      ),
    );
  }
}

class _EmployeeLookupHeaderText extends StatelessWidget {
  const _EmployeeLookupHeaderText(this.text);

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

class _EmployeeLookupRow extends StatelessWidget {
  const _EmployeeLookupRow({
    required this.stripeIndex,
    required this.displayNo,
    required this.employee,
  });

  final int stripeIndex;
  final int displayNo;
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: erpPopupListRowBackground(stripeIndex),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(employee),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 56, child: _EmployeeLookupCell('$displayNo')),
              Expanded(flex: 1, child: _EmployeeLookupCell(employee.name)),
              Expanded(
                flex: 1,
                child: _EmployeeLookupCell(employee.department),
              ),
              Expanded(flex: 1, child: _EmployeeLookupCell(employee.jobTitle)),
              Expanded(flex: 2, child: _EmployeeLookupCell(employee.userId)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeLookupCell extends StatelessWidget {
  const _EmployeeLookupCell(this.text);

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

InputDecoration _employeeLookupSearchDecoration(String hint) {
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
