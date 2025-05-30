package com.appsdeveloperblog.photoapp.api.gateway.filter;

import com.appsdeveloperblog.photoapp.api.gateway.JwtUtil;
import io.jsonwebtoken.JwtException;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class AuthorizationHeaderFilter extends AbstractGatewayFilterFactory<AuthorizationHeaderFilter.Config> {

    private final Environment environment;

    public AuthorizationHeaderFilter(Environment environment) {
        super(Config.class);
        this.environment = environment;
    }


    public static class Config {

    }

    @Override
    public GatewayFilter apply(Config config) {

        return (exchange, chain) -> {
            ServerHttpRequest request = exchange.getRequest();
            if (!request.getHeaders().containsKey("Authorization")) {
                return onError(exchange, "No authorization header", HttpStatus.UNAUTHORIZED);
            }
            String authorizationHeader = request.getHeaders().getFirst("Authorization");
            if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
                return onError(exchange, "Invalid authorization header format", HttpStatus.UNAUTHORIZED);
            }
            String jwtToken = authorizationHeader.replace("Bearer ", "");

            JwtUtil jwtUtil = new JwtUtil(
                    environment.getProperty("token.secret"),
                    environment.getProperty("token.expiration.time", Long.class, 1800L)
            );


            String subject="";
            try {
                subject = jwtUtil.extractSubject(jwtToken); // ⚠️ Valide la signature et expire
            } catch (JwtException e) {
                return onError(exchange, "Invalid JWT: " + e.getMessage(), HttpStatus.UNAUTHORIZED);
            }

            // Propagation de l'utilisateur courant
            ServerHttpRequest modifiedRequest = request.mutate()
                    .header("X-User-Email", subject)
                    .build();

            return chain.filter(exchange.mutate().request(modifiedRequest).build());
        };
    }

    private Mono<Void> onError(ServerWebExchange exchange, String noAuthorizationHader, HttpStatus httpStatus) {
        ServerHttpResponse httpResponse = exchange.getResponse();
        httpResponse.setStatusCode(httpStatus);
        return httpResponse.setComplete();
    }

}
