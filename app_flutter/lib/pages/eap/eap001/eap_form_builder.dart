// 전자결재 양식 빌더 / 기안 입력 (web iframe / stub).

export 'package:app_flutter/pages/eap/eap001/eap_form_builder_stub.dart'
    if (dart.library.html) 'package:app_flutter/pages/eap/eap001/eap_form_builder_web.dart'
    show
        EapFormBuilderController,
        EapFormBuilderHost,
        EapFormFillController,
        EapFormFillHost;

/// HTML에 양식 빌더 필드(data-eap-type)가 포함돼 있는지 확인.
bool eapHtmlHasFormFields(String html) {
  if (html.contains('data-eap-type=')) return true;
  return html.contains('eap-field') ||
      html.contains('eap-widget') ||
      html.contains('eap-grid-field');
}
