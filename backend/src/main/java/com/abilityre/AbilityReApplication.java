package com.abilityre;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** 后端服务入口；Spring Boot 会从这里扫描控制器、服务和数据库组件。 */
@SpringBootApplication
public class AbilityReApplication {
    public static void main(String[] args) {
        SpringApplication.run(AbilityReApplication.class, args);
    }
}
