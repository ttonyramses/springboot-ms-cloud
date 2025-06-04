package com.appsdeveloperblog.photoapp.api.gateway.configuration;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "application")
@Data
@RefreshScope
public class ApplicationConfiguration {

    private Token token;
    private String loginUrlPath;

    @Data
    public static class Token {
        private long expirationTime;
        private String secret;
    }
}
