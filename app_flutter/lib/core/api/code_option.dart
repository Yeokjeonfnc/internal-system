import 'package:json_annotation/json_annotation.dart';

part 'code_option.g.dart';

@JsonSerializable()
class CodeOption {
  const CodeOption({required this.codeCd, required this.codeNm});

  final String codeCd;
  final String codeNm;

  factory CodeOption.fromJson(Map<String, dynamic> json) =>
      _$CodeOptionFromJson(json);

  Map<String, dynamic> toJson() => _$CodeOptionToJson(this);
}
