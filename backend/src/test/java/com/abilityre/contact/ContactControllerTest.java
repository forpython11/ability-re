package com.abilityre.contact;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/** 验证停用后的联系接口始终拒绝写入，不会因为请求内容不同而重新开放。 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ContactControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void returnsGoneBecauseContactFormIsDisabled() throws Exception {
        mockMvc.perform(post("/api/contact")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "张三",
                                  "email": "zhangsan@example.com",
                                  "message": "我想交流个人技术学习记录。"
                                }
                                """))
                .andExpect(status().isGone())
                .andExpect(jsonPath("$.code").value(410))
                .andExpect(jsonPath("$.message").value("contact form disabled"));
    }

    @Test
    void ignoresInvalidPayloadWhenContactFormIsDisabled() throws Exception {
        // 接口已整体停用，所以无效表单也应返回 410，而不是进入字段校验流程。
        mockMvc.perform(post("/api/contact")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "",
                                  "email": "not-email",
                                  "message": "太短"
                                }
                                """))
                .andExpect(status().isGone())
                .andExpect(jsonPath("$.code").value(410));
    }
}
