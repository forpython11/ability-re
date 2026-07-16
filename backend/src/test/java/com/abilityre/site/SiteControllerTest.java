package com.abilityre.site;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/** 通过完整 Spring 上下文验证 Flyway 数据、JPA 查询和 HTTP 响应能正确串联。 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SiteControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void returnsHomePageContentFromDatabase() throws Exception {
        mockMvc.perform(get("/api/site/home"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.hero.title").value("能力重构个人技术记录"))
                .andExpect(jsonPath("$.data.features", hasSize(3)))
                .andExpect(jsonPath("$.data.features[0].title").value("前端学习笔记"))
                .andExpect(jsonPath("$.data.learningRecords", hasSize(1)))
                .andExpect(jsonPath("$.data.learningRecords[0].slug").value("kubernetes-minikube"));
    }

    @Test
    void returnsLearningRecordDetailFromDatabase() throws Exception {
        mockMvc.perform(get("/api/site/learning-records/kubernetes-minikube"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.slug").value("kubernetes-minikube"))
                .andExpect(jsonPath("$.data.title").value("从零跑通部署入口：Minikube、Nginx 反向代理、域名解析与备案排查"))
                .andExpect(jsonPath("$.data.blocks", hasSize(10)))
                .andExpect(jsonPath("$.data.blocks[0].heading").value("我到底做了什么"))
                // V5 应把已完成的 Dockerfile 工作推进为当前 Minikube/Helm 待办。
                .andExpect(jsonPath("$.data.blocks[9].heading").value("下一步"))
                .andExpect(jsonPath("$.data.blocks[9].body", containsString("当前 Git SHA")))
                .andExpect(jsonPath("$.data.blocks[9].body", containsString("Nginx 网关")));
    }

    @Test
    void allowsFrontendCorsPreflight() throws Exception {
        // 浏览器发送正式跨域请求前，会先用 OPTIONS 确认该来源是否被允许。
        mockMvc.perform(options("/api/site/home")
                        .header("Origin", "http://localhost:5173")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
    }
}
