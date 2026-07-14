package com.yeokjeon.erp.development.util;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import org.springframework.util.StringUtils;

/** sale_zone_mst.geometry_data JSON 직렬화·검증. */
public final class GeometryJson {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final List<String> ALLOWED_TYPES = List.of("POLYGON", "CIRCLE");

    private GeometryJson() {}

    public static Map<String, Object> toMap(String json) {
        if (!StringUtils.hasText(json)) {
            return null;
        }
        try {
            return MAPPER.readValue(json, new TypeReference<>() {});
        } catch (Exception e) {
            throw new IllegalArgumentException("geometry_data JSON 파싱 실패", e);
        }
    }

    /** 목록·지도 응답 — 잘못된 JSON이 있어도 전체 API가 실패하지 않도록. */
    public static Map<String, Object> toMapLenient(String json) {
        if (!StringUtils.hasText(json)) {
            return null;
        }
        try {
            return MAPPER.readValue(json, new TypeReference<>() {});
        } catch (Exception e) {
            return null;
        }
    }

    public static String toJson(Map<String, Object> data) {
        if (data == null || data.isEmpty()) {
            return null;
        }
        try {
            return MAPPER.writeValueAsString(data);
        } catch (Exception e) {
            throw new IllegalArgumentException("geometry_data JSON 직렬화 실패", e);
        }
    }

    public static void validate(String geometryType, Map<String, Object> data) {
        if (!StringUtils.hasText(geometryType)
                || !ALLOWED_TYPES.contains(geometryType.trim().toUpperCase())) {
            throw new IllegalArgumentException("geometryType은 POLYGON 또는 CIRCLE 이어야 합니다.");
        }
        if (data == null || data.isEmpty()) {
            throw new IllegalArgumentException("geometryData가 비어 있습니다.");
        }
        String type = geometryType.trim().toUpperCase();
        if ("POLYGON".equals(type)) {
            Object paths = data.get("paths");
            if (!(paths instanceof List<?> list) || list.size() < 3) {
                throw new IllegalArgumentException("POLYGON paths는 3개 이상이어야 합니다.");
            }
            return;
        }
        if (data.get("center") == null || data.get("radius") == null) {
            throw new IllegalArgumentException("CIRCLE center·radius가 필요합니다.");
        }
    }

    public static Map<String, Object> emptyMap() {
        return Collections.emptyMap();
    }
}
