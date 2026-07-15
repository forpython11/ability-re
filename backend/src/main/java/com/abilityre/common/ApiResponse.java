package com.abilityre.common;

/**
 * 所有业务接口共用的 JSON 外层结构。
 * code 表示业务结果，data 才是页面真正使用的数据。
 */
public record ApiResponse<T>(int code, String message, T data) {
    /** 成功响应统一使用业务码 0，减少各控制器重复组装返回值。 */
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(0, "success", data);
    }
}
