package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.service;

import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.dto.UserResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "users-ws")
public interface UserServiceClient {

    @GetMapping("/api/users/validate/{userId}")
    UserResponse validateToken(@RequestHeader("Authorization") String token, @PathVariable("userId")  Long userId);
}