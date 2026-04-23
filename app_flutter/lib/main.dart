// Flutter 앱 진입점: Riverpod 과 GoRouter 로 ERP 앱을 띄운다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';

void main() {
  runApp(const ProviderScope(child: YeokjeonApp()));
}

class YeokjeonApp extends StatelessWidget {
  const YeokjeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '(주)역전에프앤씨',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
