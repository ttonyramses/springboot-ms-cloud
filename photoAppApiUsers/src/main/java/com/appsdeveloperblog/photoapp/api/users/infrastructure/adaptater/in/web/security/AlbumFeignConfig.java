package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security;

import feign.codec.ErrorDecoder;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AlbumFeignConfig {

    @Bean
    public ErrorDecoder errorDecoder(@Qualifier("albumServiceErrorDecoder") ErrorDecoder decoder) {
        return decoder;
    }
}
