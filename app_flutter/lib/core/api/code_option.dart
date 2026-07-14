import 'package:json_annotation/json_annotation.dart';

part 'code_option.g.dart';

/// `code_mst` 조회 한 행 — 백엔드 `CodeMstDto` JSON 키와 동일.
abstract final class CodeMstApiJsonKeys {
  static const String codeCd = 'codeCd';
  static const String codeNm = 'codeNm';
}

@JsonSerializable(createFactory: false)
class CodeOption {
  const CodeOption({required this.codeCd, required this.codeNm});

  @JsonKey(name: CodeMstApiJsonKeys.codeCd)
  final String codeCd;

  @JsonKey(name: CodeMstApiJsonKeys.codeNm)
  final String codeNm;

  factory CodeOption.fromJson(Map<String, dynamic> json) {
    final cd = json[CodeMstApiJsonKeys.codeCd];
    final nm = json[CodeMstApiJsonKeys.codeNm];
    return CodeOption(
      codeCd: cd?.toString() ?? '',
      codeNm: nm?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$CodeOptionToJson(this);
}

/// 공통코드 REST — 백엔드 `CommonCodeController` (`/codes`).
abstract final class CodeMstApiPaths {
  static const String root = '/codes';
}

/// `GET /codes` 쿼리 — `CommonCodeService.getCodesByGroup`와 동일.
abstract final class CodeMstQueryParamKeys {
  static const String grpCd = 'grpCd';
}
