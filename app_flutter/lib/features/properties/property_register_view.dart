// 물건 신규 등록 화면(상세와 동일 셸).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/features/properties/property_detail_view.dart';

/// 개발관리 > 물건관리 > 등록 화면.
///
/// 상세 화면과 동일한 패널([PropertyInfoPanel])을 재사용하되,
/// 초기값(property)을 비워 모든 필드가 빈 상태로 표시되도록 합니다.
class PropertyRegisterView extends StatelessWidget {
  const PropertyRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 제목은 셸 상단 배너에만 표시(중복 제목 띠 제거).
            const PropertyInfoPanel(property: null, initiallyEditing: true),
          ],
        ),
      ),
    );
  }
}
