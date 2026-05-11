package com.yeokjeon.erp.development.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
public class AddressGeocodingService {

    private final RestClient restClient;
    private final String kakaoRestApiKey;

    public AddressGeocodingService(
            @Value("${external.kakao.rest-api-key:}") String kakaoRestApiKey
    ) {
        this.restClient = RestClient.builder()
                .baseUrl("https://dapi.kakao.com")
                .build();
        this.kakaoRestApiKey = kakaoRestApiKey;
    }

    public Optional<Coordinates> geocode(String address) {
        if (!StringUtils.hasText(address)) {
            return Optional.empty();
        }
        if (!StringUtils.hasText(kakaoRestApiKey)) {
            log.warn("Kakao REST API 키가 설정되지 않아 주소 좌표 변환을 건너뜁니다.");
            return Optional.empty();
        }

        try {
            ResponseEntity<Map<String, Object>> response = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/v2/local/search/address.json")
                            .queryParam("query", address.trim())
                            .build())
                    .header(HttpHeaders.AUTHORIZATION, "KakaoAK " + kakaoRestApiKey.trim())
                    .retrieve()
                    .toEntity(new ParameterizedTypeReference<>() {
                    });

            Map<String, Object> body = response.getBody();
            if (body == null) return Optional.empty();

            Object documentsValue = body.get("documents");
            if (!(documentsValue instanceof List<?> documents) || documents.isEmpty()) {
                log.warn("주소 좌표 검색 결과가 없습니다: {}", address);
                return Optional.empty();
            }

            Object firstValue = documents.get(0);
            if (!(firstValue instanceof Map<?, ?> first)) {
                return Optional.empty();
            }

            BigDecimal longitude = parseCoordinate(first.get("x"));
            BigDecimal latitude = parseCoordinate(first.get("y"));
            if (latitude == null || longitude == null) {
                log.warn("주소 좌표 응답을 숫자로 변환할 수 없습니다: {}", address);
                return Optional.empty();
            }
            log.debug("주소 좌표 변환 완료: {} -> {}, {}", address, latitude, longitude);
            return Optional.of(new Coordinates(latitude, longitude));
        } catch (Exception e) {
            log.warn("주소 좌표 변환 실패: {}", address, e);
            return Optional.empty();
        }
    }

    private BigDecimal parseCoordinate(Object value) {
        if (value == null) return null;
        try {
            return new BigDecimal(value.toString()).setScale(7, RoundingMode.HALF_UP);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public record Coordinates(BigDecimal latitude, BigDecimal longitude) {
    }
}
