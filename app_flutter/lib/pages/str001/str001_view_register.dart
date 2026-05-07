// 가맹점 신규 등록 화면(상세와 동일 탭 골격, 데이터 없음).

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/str001/str001_view_detail.dart';

/// 목록의 [+] 등록과 동일한 상세 레이아웃으로 빈 폼만 연다.
class StoreRegisterView extends StatelessWidget {
  const StoreRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoreDetailView(isRegisterMode: true);
  }
}
