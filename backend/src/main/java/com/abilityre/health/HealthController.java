package com.abilityre.health;

import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** 提供包含数据库连通性的业务健康检查，供部署脚本判断服务是否真正可用。 */
@RestController
public class HealthController {
    private final JdbcTemplate jdbcTemplate;

    public HealthController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/api/health")
    public ResponseEntity<Map<String, String>> health() {
        try {
            // 只执行最轻量查询；Java 进程正常但数据库不可用时也应判定为失败。
            Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            if (result == null || result != 1) {
                return unavailable();
            }
            return ResponseEntity.ok(Map.of("status", "ok", "service", "ability-re-backend"));
        } catch (DataAccessException exception) {
            // 不把数据库异常详情返回公网，避免泄露连接和表结构信息。
            return unavailable();
        }
    }

    private ResponseEntity<Map<String, String>> unavailable() {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of("status", "unavailable", "service", "ability-re-backend"));
    }
}
