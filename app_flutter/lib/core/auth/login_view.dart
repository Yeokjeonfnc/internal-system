import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
            style: GoogleFonts.notoSansKr(
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
                child: Text(
                  '확인',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 로고 또는 제목
                    Text(
                      '역전F&C',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jua(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '로그인',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jua(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: FormStylePalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 아이디 입력
                    Text(
                      '아이디',
                      style: GoogleFonts.jua(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FormStylePalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userIdController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: '아이디를 입력하세요',
                        filled: true,
                        fillColor: FormStylePalette.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.accentRed,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: FormStylePalette.textPrimary,
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 20),

                    // 비밀번호 입력
                    Text(
                      '비밀번호',
                      style: GoogleFonts.jua(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FormStylePalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 입력하세요',
                        filled: true,
                        fillColor: FormStylePalette.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: FormStylePalette.panelBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.accentRed,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
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
                      style: GoogleFonts.notoSansKr(
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
                            style: GoogleFonts.notoSansKr(
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                          : Text(
                              '로그인',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
