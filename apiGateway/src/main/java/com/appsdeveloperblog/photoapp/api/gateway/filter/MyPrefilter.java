package com.appsdeveloperblog.photoapp.api.gateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class MyPrefilter implements org.springframework.cloud.gateway.filter.GlobalFilter {

    final Logger logger = LoggerFactory.getLogger(MyPrefilter.class);

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        logger.info("MyPrefilter is called");

        String requestPath = exchange.getRequest().getPath().toString();
        exchange.getRequest().getHeaders().forEach((name, values) -> logger.info("{} : {}", name, values));
        logger.info("Request Path : {}", requestPath);
        return chain.filter(exchange);
    }
}
