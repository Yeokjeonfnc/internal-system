-- 다우오피스 연동 폐기. 자체 전자결재에서 쓰지 않는 토큰·사용자 매핑 테이블만 제거한다.
-- eap_form_config / erp_approval_mappings 는 계속 사용한다.

DROP TABLE IF EXISTS public.daou_api_tokens;
DROP TABLE IF EXISTS public.employee_daou_user_map;
