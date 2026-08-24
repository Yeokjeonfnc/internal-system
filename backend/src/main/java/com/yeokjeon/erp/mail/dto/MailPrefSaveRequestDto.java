package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.Map;

/**
 * 개인 설정 저장 요청 (mal001-E).
 *
 * <p>키-값 다건을 한 번에 받는다. 설정 화면은 여러 항목을 고친 뒤 "저장"을 한 번 누르는
 * 형태라, 항목마다 PUT 을 던지면 중간에 하나가 실패했을 때 화면과 DB 가 반쯤 어긋난 채
 * 남는다. 한 요청 = 한 트랜잭션이어야 그 상태가 생기지 않는다.
 *
 * <p><b>부분 갱신(PUT-as-PATCH)이다.</b> 요청에 없는 키는 지우지 않는다. 전체 치환으로
 * 만들면 구버전 화면이 자기가 모르는 새 설정을 통째로 날려 버린다.
 * 값을 지우려면 빈 문자열을 명시적으로 보낸다.
 *
 * @param prefs 키 → 값. 키 50자·값 500자는 컬럼 길이 그대로다(varchar(50)/varchar(500)).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailPrefSaveRequestDto(
        @NotEmpty(message = "저장할 설정이 없습니다.")
        @Size(max = 100, message = "한 번에 최대 100개까지 저장할 수 있습니다.")
        Map<
                @Size(max = 50, message = "설정 키는 50자를 넘을 수 없습니다.") String,
                @Size(max = 500, message = "설정 값은 500자를 넘을 수 없습니다.") String> prefs) {
}
