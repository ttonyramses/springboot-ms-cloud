package com.appsdeveloperblog.photoapp.api.gateway.configuration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Mono;

@Configuration
public class GlobalFilterConfiguration {

    final Logger logger = LoggerFactory.getLogger(GlobalFilterConfiguration.class);

    @Bean
    public GlobalFilter secondGlobalFilter() {
        return (exchange, chain) -> {
            logger.info("My second Global pre-Filter is called");
            return chain.filter(exchange).then(Mono.fromRunnable(() -> {
                logger.info("My second Global post-Filter is completed");
            }));
        };
    }

    @Bean
    public GlobalFilter thirdGlobalFilter() {
        return (exchange, chain) -> {
            logger.info("My third Global pre-Filter is called");
            return chain.filter(exchange).then(Mono.fromRunnable(() -> {
                logger.info("My third Global post-Filter is completed");
            }));
        };
    }
}
