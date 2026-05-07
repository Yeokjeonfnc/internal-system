package com.yeokjeon.erp.common;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * {@code @RequestBody Map<String, Object>} 파싱 — DTO 없이 요청 본문 처리.
 */
public final class RequestMapUtil {

    private RequestMapUtil() {}

    public static String reqStr(Map<String, ?> m, String key) {
        String s = optStr(m, key);
        if (s == null || s.isBlank()) {
            throw new IllegalArgumentException(key + "은(는) 필수입니다.");
        }
        return s;
    }

    public static String optStr(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        String s = v.toString().trim();
        return s.isEmpty() ? null : s;
    }

    public static Integer optInt(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        if (v instanceof Number n) return n.intValue();
        try {
            return Integer.parseInt(v.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public static int reqInt(Map<String, ?> m, String key) {
        Integer n = optInt(m, key);
        if (n == null) {
            throw new IllegalArgumentException(key + "은(는) 필수입니다.");
        }
        return n;
    }

    public static Long optLong(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        if (v instanceof Number n) return n.longValue();
        try {
            return Long.parseLong(v.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public static BigDecimal optBigDecimal(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        if (v instanceof BigDecimal bd) return bd;
        if (v instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try {
            return new BigDecimal(v.toString().trim());
        } catch (Exception e) {
            return null;
        }
    }

    public static Boolean optBool(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        if (v instanceof Boolean b) return b;
        return Boolean.parseBoolean(v.toString().trim());
    }

    public static LocalDate optLocalDate(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        if (v instanceof LocalDate d) return d;
        String s = v.toString().trim();
        if (s.isEmpty()) return null;
        return LocalDate.parse(s.length() >= 10 ? s.substring(0, 10) : s);
    }

    public static LocalDateTime optLocalDateTime(Map<String, ?> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        if (v == null) return null;
        if (v instanceof LocalDateTime dt) return dt;
        String s = v.toString().trim();
        if (s.isEmpty()) return null;
        return LocalDateTime.parse(s.replace(" ", "T"));
    }

    public static Character optChar(Map<String, ?> m, String key) {
        String s = optStr(m, key);
        if (s == null || s.isEmpty()) return null;
        return s.charAt(0);
    }

    @SuppressWarnings("unchecked")
    public static List<String> optStringList(Map<String, ?> m, String key) {
        if (m == null) return List.of();
        Object v = m.get(key);
        if (!(v instanceof List<?> list)) return List.of();
        List<String> out = new ArrayList<>();
        for (Object e : list) {
            if (e == null) continue;
            String s = e.toString().trim();
            if (!s.isEmpty()) out.add(s);
        }
        return out;
    }

    public static String joinCsvDistinct(List<String> ids) {
        if (ids == null || ids.isEmpty()) return null;
        Set<String> set = new LinkedHashSet<>();
        for (String raw : ids) {
            if (raw == null) continue;
            String t = raw.trim();
            if (!t.isEmpty()) set.add(t);
        }
        if (set.isEmpty()) return null;
        return String.join(",", set);
    }

    @SuppressWarnings("unchecked")
    public static List<Map<String, Object>> optMapList(Map<String, ?> m, String key) {
        if (m == null) return List.of();
        Object v = m.get(key);
        if (!(v instanceof List<?> list)) return List.of();
        List<Map<String, Object>> out = new ArrayList<>();
        for (Object e : list) {
            if (e instanceof Map<?, ?> raw) {
                Map<String, Object> one = new java.util.LinkedHashMap<>();
                for (Map.Entry<?, ?> en : raw.entrySet()) {
                    one.put(String.valueOf(en.getKey()), en.getValue());
                }
                out.add(one);
            }
        }
        return out;
    }
}
