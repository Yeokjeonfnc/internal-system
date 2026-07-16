package com.yeokjeon.erp;

import java.util.Locale;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class YeokjeonErpApplication {

    /** Windows CP949 콘솔에서 UTF-8 로그가 깨질 때 기본 MS949. UTF-8 터미널은 -Dlogging.charset.console=UTF-8. */
    static {
        if (System.getProperty("os.name", "").toLowerCase(Locale.ROOT).contains("win")) {
            if (System.getProperty("logging.charset.console") == null
                    && System.getenv("LOGGING_CHARSET_CONSOLE") == null) {
                System.setProperty("logging.charset.console", "MS949");
            }
        }
    }

    public static void main(String[] args) {
        // DB/API 시각을 서울 기준으로 통일 (TIMESTAMPTZ OffsetDateTime)
        java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Seoul"));
        SpringApplication.run(YeokjeonErpApplication.class, args);
    }
}
