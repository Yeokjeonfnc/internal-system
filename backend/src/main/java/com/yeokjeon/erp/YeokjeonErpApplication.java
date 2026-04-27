package com.yeokjeon.erp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class YeokjeonErpApplication {

    public static void main(String[] args) {
        SpringApplication.run(YeokjeonErpApplication.class, args);
    }
}
