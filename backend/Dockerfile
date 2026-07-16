# 默认使用与 CI 一致的 Java 21 构建镜像和精简 JRE 运行镜像。
# 国内网络构建时可以通过 --build-arg 替换为可访问的镜像代理地址。
ARG MAVEN_IMAGE=maven:3.9.9-eclipse-temurin-21
ARG JRE_IMAGE=eclipse-temurin:21-jre-alpine

# 第一阶段负责编译、执行测试并生成 Spring Boot 可执行 JAR。
FROM ${MAVEN_IMAGE} AS build

WORKDIR /workspace

# 先复制依赖描述和 Maven 镜像配置，再复制后端源码。
COPY pom.xml maven-settings.xml ./
COPY src ./src
# package 会执行测试并生成可执行 JAR，测试失败时镜像构建也会失败。
# BuildKit 缓存会在网络重试或后续构建时保留已下载依赖；HTTP 重试用于缓解国内镜像偶发断流。
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -ntp -s maven-settings.xml \
    -Dmaven.wagon.http.retryHandler.count=5 \
    package

# 第二阶段只保留 JRE 和应用 JAR，不把 Maven、源码和测试产物带入运行镜像。
FROM ${JRE_IMAGE} AS runtime

# 使用专用非 root 用户运行后端，降低容器进程被利用后的权限范围。
RUN addgroup -S abilityre \
    && adduser -S -G abilityre -h /app abilityre

WORKDIR /app

COPY --from=build --chown=abilityre:abilityre \
    /workspace/target/backend-0.0.1-SNAPSHOT.jar ./app.jar

USER abilityre

# EXPOSE 只声明容器监听端口，实际端口映射由 Compose 或 Kubernetes Service 决定。
EXPOSE 18080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
