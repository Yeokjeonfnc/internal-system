// 물건 신규 등록 화면(상세와 동일 셸).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/pages/development/dev002/dev002_view_detail.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';

/// 개발관리 > 물건관리 > 등록 화면.
///
/// 상세 화면과 동일한 패널([PropertyInfoPanel])을 재사용하되,
/// 초기값(property)을 비워 모든 필드가 빈 상태로 표시되도록 합니다.
class PropertyRegisterView extends StatefulWidget {
  const PropertyRegisterView({super.key});

  static const List<String> _tabTitles = ['기본정보', '상세조건'];

  @override
  State<PropertyRegisterView> createState() => _PropertyRegisterViewState();
}

class _PropertyRegisterViewState extends State<PropertyRegisterView> {
  final _draft = PropertyRegisterDraft();
  Property? _createdProperty;
  bool _isEditing = true;
  int _formSessionEpoch = 0;

  void _handleSaved(Property property) {
    setState(() {
      _createdProperty = property;
      _isEditing = false;
      _formSessionEpoch++;
    });
  }

  Future<void> _handleSharedCancelEditing() async {
    if (_createdProperty != null) {
      _draft.hydrateFromProperty(_createdProperty!);
    }
    setState(() {
      _isEditing = false;
      _formSessionEpoch++;
    });
    if (!mounted) return;
    await showAlertDialog(context, '취소되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return DetailScreenWithTabs(
      /// 제목은 셸 상단 배너에만 표시(중복 제목 띠 제거).
      title: const SizedBox.shrink(),
      tabTitles: PropertyRegisterView._tabTitles,
      tabPages: [
        PropertyInfoPanel(
          key: ValueKey('prop_reg_0_$_formSessionEpoch'),
          property: _createdProperty,
          fixedTabIndex: 0,
          onSaved: _handleSaved,
          registerDraft: _draft,
          sharedEditing: _isEditing,
          onEditModeChanged: (value) => setState(() => _isEditing = value),
          onSharedCancelEditing: _handleSharedCancelEditing,
        ),
        PropertyInfoPanel(
          key: ValueKey('prop_reg_1_$_formSessionEpoch'),
          property: _createdProperty,
          fixedTabIndex: 1,
          onSaved: _handleSaved,
          registerDraft: _draft,
          sharedEditing: _isEditing,
          onEditModeChanged: (value) => setState(() => _isEditing = value),
          onSharedCancelEditing: _handleSharedCancelEditing,
        ),
      ],
    );
  }
}
