package com.yeokjeon.erp.mail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Size;

/**
 * 메일 플래그(읽음·중요표시·스팸·담당자·연결) 부분 수정 요청.
 *
 * <p>모든 필드가 nullable 이다. PATCH 라서 "보내지 않은 필드는 건드리지 않는다"가
 * 성립해야 하는데, 원시 타입을 쓰면 false 와 "안 보냄"을 구분할 수 없다.
 * XML 이 null 인 필드를 COALESCE 로 기존 컬럼값으로 되돌린다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MailUpdateFlagsRequestDto(
        Boolean read,
        /**
         * 중요표시(별).
         *
         * <p>목록 응답({@code MailListItemDto.star})에는 처음부터 있었는데 이 요청 DTO 에만
         * 빠져 있어서, 화면에서 별을 눌러도 서버에 반영되지 않았다. 일괄 동작(STAR/UNSTAR)
         * 으로는 되던 것이 단건 토글에서만 안 되던 상태다.
         */
        Boolean star,
        Boolean spam,
        /** 담당자 배정. {@code userId} 라는 이름을 쓰지 않는 이유는 AuthTokenFilter 예약어이기 때문 */
        @Size(max = 50) String ownerUserId,
        Integer partnerIdx,
        Long mappingId) {
}
