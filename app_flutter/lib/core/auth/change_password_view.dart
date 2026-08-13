// 비밀번호 변경 화면.
//
// 초기화된 비밀번호로 로그인하면(`mustChangePassword`) 라우터가 이 화면으로 강제 이동시키고,
// 변경을 마치기 전에는 다른 화면으로 나갈 수 없다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_api_service.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || next.isEmpty) {
      setState(() => _error = '비밀번호를 모두 입력해 주세요.');
      return;
    }
    if (next.trim().length < 8) {
      setState(() => _error = '새 비밀번호는 8자 이상이어야 합니다.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = '새 비밀번호가 서로 일치하지 않습니다.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await AuthApiService().changePassword(
      currentPassword: current,
      newPassword: next,
    );

    if (!mounted) return;
    if (result.failure != null) {
      setState(() {
        _submitting = false;
        _error = result.failure;
      });
      return;
    }

    // 변경 완료 — 재발급 토큰으로 갈아끼우고, 강제 플래그를 내리면
    // 라우터가 원래 화면으로 보내준다.
    await context
        .read<AuthProvider>()
        .markPasswordChanged(reissuedToken: result.token);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mustChange =
        context.watch<AuthProvider>().profile?.mustChangePassword ?? false;

    return Scaffold(
      backgroundColor: AppTheme.appSurface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.hairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '비밀번호 변경',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mustChange
                        ? '보안 정책에 따라 비밀번호가 초기화되었습니다.\n계속하려면 새 비밀번호를 설정해 주세요.'
                        : '새 비밀번호를 설정합니다.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(_currentCtrl, '현재 비밀번호'),
                  const SizedBox(height: 12),
                  _field(_newCtrl, '새 비밀번호 (8자 이상)'),
                  const SizedBox(height: 12),
                  _field(_confirmCtrl, '새 비밀번호 확인'),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.accentRed,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('변경하기'),
                  ),
                  if (mustChange) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => context.read<AuthProvider>().logout(),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      enabled: !_submitting,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
