import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/auth/auth_api_service.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberPassword = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.rememberPassword) {
      _userIdController.text = authProvider.savedUserId ?? '';
      _passwordController.text = authProvider.savedPassword ?? '';
      _rememberPassword = true;
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty) {
      _showMessage('아이디를 입력해주세요.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthApiService().login(
        userId: userId,
        userPassword: password,
      );

      if (!mounted) return;

      if (result != null) {
        final auth = context.read<AuthProvider>();
        await auth.login(
          result,
          rememberPassword: _rememberPassword,
          userId: userId,
          password: password,
        );

        if (mounted) {
          final target = auth.firstAllowedPath;
          if (auth.usesMenuPermissions && target == null) {
            _showMessage('접근 가능한 메뉴가 없습니다. 관리자에게 권한을 요청하세요.');
            return;
          }
          context.go(target ?? '/');
        }
      } else {
        _showMessage('아이디 또는 비밀번호가 일치하지 않습니다.');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final isConnection =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      final baseHint = '\n(${ApiClient.resolveBaseUrl()})';
      _showMessage(
        isConnection
            ? '서버에 연결할 수 없습니다.\nPC에서 백엔드를 실행했는지 확인하세요.$baseHint'
            : '로그인 중 오류가 발생했습니다.',
      );
    } catch (e) {
      if (mounted) {
        _showMessage('로그인 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.brandFontFamily,
              fontSize: 15,
              color: FormStylePalette.textPrimary,
            ),
          ),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appSurface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 로고
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/logo_yj.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '역전 F&C',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '매장 운영 시스템',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 아이디 입력
                    const Text(
                      '아이디',
                      style: TextStyle(
                        fontFamily: AppTheme.brandFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: FormStylePalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _userIdController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: '아이디를 입력하세요',
                        hintStyle: const TextStyle(
                          color: AppTheme.textPlaceholder,
                        ),
                        filled: true,
                        fillColor: FormStylePalette.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.accentRed,
                            width: 1.4,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: AppTheme.brandFontFamily,
                        fontSize: 14,
                        color: FormStylePalette.textPrimary,
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 18),

                    // 비밀번호 입력
                    const Text(
                      '비밀번호',
                      style: TextStyle(
                        fontFamily: AppTheme.brandFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: FormStylePalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 입력하세요',
                        hintStyle: const TextStyle(
                          color: AppTheme.textPlaceholder,
                        ),
                        filled: true,
                        fillColor: FormStylePalette.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.accentRed,
                            width: 1.4,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: FormStylePalette.textSecondary,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: AppTheme.brandFontFamily,
                        fontSize: 14,
                        color: FormStylePalette.textPrimary,
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 저장 체크박스
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () {
                              setState(
                                () => _rememberPassword = !_rememberPassword,
                              );
                            },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberPassword,
                              onChanged: _isLoading
                                  ? null
                                  : (v) {
                                      setState(
                                        () => _rememberPassword = v ?? false,
                                      );
                                    },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '비밀번호 저장',
                            style: const TextStyle(
                              fontFamily: AppTheme.brandFontFamily,
                              fontSize: 14,
                              color: FormStylePalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 로그인 버튼
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: FormStylePalette.textMuted
                            .withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
