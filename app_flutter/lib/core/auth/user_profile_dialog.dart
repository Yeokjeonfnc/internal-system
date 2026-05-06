import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/auth/auth_api_service.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    if (text.length <= 3) {
      formatted = text;
    } else if (text.length <= 7) {
      formatted = '${text.substring(0, 3)}-${text.substring(3)}';
    } else if (text.length <= 11) {
      formatted =
          '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7)}';
    } else {
      formatted =
          '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, 11)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Future<void> showUserProfileDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) => const _UserProfileDialog(),
  );
}

class _UserProfileDialog extends StatefulWidget {
  const _UserProfileDialog();

  @override
  State<_UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<_UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _email;
  String? _joinDate;
  String? _positionCd;
  String _positionNm = '사원';
  bool _svYn = false;
  bool _tagYn = false;
  bool _isLoading = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthApiService().getUserProfile(userId);

      if (!mounted) return;

      if (user != null) {
        debugPrint('사용자 정보: $user');
        debugPrint('joinDt 값: ${user['joinDt']}');

        setState(() {
          _nameController.text = user['userNm']?.toString() ?? '';
          _email = user['email']?.toString() ?? '';
          _deptController.text = user['deptNm']?.toString() ?? '';
          _phoneController.text = _formatPhoneNumber(
            user['userPhone']?.toString(),
          );
          _joinDate = user['joinDt']?.toString() ?? '미입력';
          _positionCd = user['positionCd']?.toString();
          _positionNm = user['positionNm']?.toString() ?? '사원';
          _svYn = user['svYn']?.toString() == 'Y';
          _tagYn = user['tagYn']?.toString() == 'Y';
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('사용자 정보를 불러오는데 실패했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    final text = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) return '';

    if (text.length <= 3) {
      return text;
    } else if (text.length <= 7) {
      return '${text.substring(0, 3)}-${text.substring(3)}';
    } else if (text.length <= 11) {
      return '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7)}';
    } else {
      return '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, 11)}';
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 비밀번호 변경 시 확인
    if (_showPasswordFields) {
      if (_currentPasswordController.text.isEmpty) {
        _showMessage('현재 비밀번호를 입력해주세요.');
        return;
      }
      if (_newPasswordController.text.isEmpty) {
        _showMessage('새 비밀번호를 입력해주세요.');
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showMessage('새 비밀번호가 일치하지 않습니다.');
        return;
      }
      if (_newPasswordController.text.length < 8) {
        _showMessage('비밀번호는 8자 이상이어야 합니다.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      final result = await AuthApiService().updateUserProfile(
        userId: userId,
        userName: _nameController.text.trim(),
        userPassword: _showPasswordFields ? _newPasswordController.text : null,
        userPhone: _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        positionCd: _positionCd,
        svYn: _svYn ? 'Y' : 'N',
        tagYn: _tagYn ? 'Y' : 'N',
      );

      if (!mounted) return;

      if (result != null) {
        await authProvider.login(
          result,
          rememberPassword: authProvider.rememberPassword,
          userId: userId,
          password: _showPasswordFields
              ? _newPasswordController.text
              : authProvider.savedPassword ?? '',
        );

        if (mounted) {
          await _showMessageAsync('정보가 저장되었습니다.');
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else {
        _showMessage('정보 저장에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('정보 저장 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showMessageAsync(String message) async {
    if (!mounted) return;
    await showDialog(
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: FormStylePalette.inputBg,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용자 정보',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: FormStylePalette.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: FormStylePalette.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 폼
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이름
                      _buildLabel('이름'),
                      _buildTextField(
                        controller: _nameController,
                        hintText: '',
                      ),
                      const SizedBox(height: 16),

                      // 부서 (읽기 전용)
                      _buildLabel('부서'),
                      _buildTextField(
                        controller: _deptController,
                        hintText: '',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // 핸드폰번호
                      _buildLabel('핸드폰번호'),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: '010-0000-0000',
                        inputFormatters: [PhoneNumberFormatter()],
                      ),
                      const SizedBox(height: 16),

                      // 이메일 (읽기 전용)
                      _buildLabel('이메일 주소'),
                      _buildTextField(
                        controller: TextEditingController(text: _email),
                        hintText: '',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // 입사년월일 (읽기 전용)
                      _buildLabel('입사년월일'),
                      _buildTextField(
                        controller: TextEditingController(text: _joinDate),
                        hintText: '',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // 직급 (읽기 전용)
                      _buildLabel('직급'),
                      _buildTextField(
                        controller: TextEditingController(text: _positionNm),
                        hintText: '',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 변경
                      Row(
                        children: [
                          Text(
                            '비밀번호 변경',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: FormStylePalette.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _showPasswordFields,
                            onChanged: (v) {
                              setState(() => _showPasswordFields = v ?? false);
                            },
                          ),
                        ],
                      ),

                      if (_showPasswordFields) ...[
                        const SizedBox(height: 16),
                        _buildLabel('현재 비밀번호'),
                        _buildTextField(
                          controller: _currentPasswordController,
                          hintText: '',
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('신규 비밀번호'),
                        _buildTextField(
                          controller: _newPasswordController,
                          hintText: '영어,숫자,특수문자 조합 8자 이상',
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('신규 비밀번호 확인'),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hintText: '영어,숫자,특수문자 조합 8자 이상',
                          obscureText: true,
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '정보 저장',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.notoSansKr(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FormStylePalette.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: enabled
            ? Colors.white
            : FormStylePalette.panelBorder.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FormStylePalette.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FormStylePalette.panelBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: FormStylePalette.panelBorder.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.accentRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: GoogleFonts.notoSansKr(
        fontSize: 14,
        color: enabled
            ? FormStylePalette.textPrimary
            : const Color.fromARGB(255, 67, 70, 77),
      ),
    );
  }
}
