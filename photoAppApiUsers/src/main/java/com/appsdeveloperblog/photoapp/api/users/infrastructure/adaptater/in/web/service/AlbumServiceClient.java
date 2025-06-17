package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.service;

import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.AlbumResponse;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security.AlbumFeignConfig;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@FeignClient(name = "album-ws",
        configuration = AlbumFeignConfig.class)
public interface AlbumServiceClient {

    @GetMapping("/api/users/{userId}/albums")
    @CircuitBreaker(name = "album-ws", fallbackMethod = "getAlbumsCircuitBreakerFallback")
    @Retry(name = "album-ws")
    @TimeLimiter(name = "album-ws")
    CompletableFuture<List<AlbumResponse>> getAlbumsAsync(@RequestHeader("Authorization") String token, @PathVariable("userId") Long userId);

    // Version synchrone avec fallback
    @GetMapping("/api/users/{userId}/albums")
    @CircuitBreaker(name = "album-ws", fallbackMethod = "getAlbumsFallback")
    @Retry(name = "album-ws")
    List<AlbumResponse> getAlbums(@RequestHeader("Authorization") String token, @PathVariable("userId") Long userId);

    // Méthodes de fallback dans l'interface par défaut (Java 8+)
    default List<AlbumResponse> getAlbumsFallback(String token, Long userId, Throwable ex) {
        return List.of(new AlbumResponse(-1L, userId, "Service temporairement indisponible", "Les albums ne peuvent pas être récupérés pour le moment"));
    }

    default CompletableFuture<List<AlbumResponse>> getAlbumsCircuitBreakerFallback(String token, Long userId, Throwable ex) {
        return CompletableFuture.completedFuture(getAlbumsFallback(token, userId, ex));
    }
}