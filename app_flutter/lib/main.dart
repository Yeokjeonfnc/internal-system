// Flutter 앱 진입점: Riverpod 과 GoRouter 로 ERP 앱을 띄운다.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;

import 'core/api/api_client.dart';
import 'core/map/kakao_map_app_key_io.dart';
import 'core/router/app_router.dart' show appRouter, createAppRouter;
import 'core/theme/app_colors.dart';
import 'core/auth/auth_provider.dart';

late final AuthProvider _rootAuthProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 폰트는 pubspec 에 번들된 Pretendard 만 사용한다.
  // 런타임 네트워크 다운로드(fonts.gstatic.com)를 막아 첫 화면 로딩을 빠르게.
  GoogleFonts.config.allowRuntimeFetching = false;
  if (kIsWeb) {
    syncKakaoMapAppKeyToLocalStorage();
    // 웹: 브라우저 기본 우클릭 메뉴를 전역으로 끈다(메시지 컨텍스트 메뉴 등 앱 메뉴와 충돌 방지).
    // 화면별 토글은 방 전환 시 재활성화 경합이 생겨, 시작 시 한 번만 끈다.
    await BrowserContextMenu.disableContextMenu();
  }
  ApiClient.applyBaseUrl();

  _rootAuthProvider = AuthProvider();
  // 로컬 세션(SharedPreferences) 복원만 기다린다. 자동 로그인(네트워크)은
  // 내부에서 백그라운드로 처리되어 첫 프레임을 막지 않는다.
  await _rootAuthProvider.ensureSessionRestored();
  appRouter = createAppRouter(_rootAuthProvider);

  runApp(const ProviderScope(child: YeokjeonApp()));
}

class YeokjeonApp extends StatelessWidget {
  const YeokjeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<AuthProvider>.value(
          value: _rootAuthProvider,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: '(주)역전에프앤씨',
        theme: AppTheme.light,
        routerConfig: appRouter,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
      ),
    );
  }
}
