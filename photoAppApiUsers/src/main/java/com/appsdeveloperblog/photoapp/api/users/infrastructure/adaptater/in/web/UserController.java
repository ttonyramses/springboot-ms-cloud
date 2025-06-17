package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.AlbumResponse;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserDetailResponse;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserRequest;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserResponse;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.mapper.UserWebMapper;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security.JwtTokenUtil;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.service.AlbumServiceClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@Slf4j
public class UserController {

    private final Environment environment;
    private final UserUseCase userUseCase;
    private final UserWebMapper userWebMapper;
    private final JwtTokenUtil jwtTokenUtil;
    private final AlbumServiceClient albumServiceClient;

    public UserController(Environment environment, UserUseCase userUseCase, UserWebMapper userWebMapper, JwtTokenUtil jwtTokenUtil, AlbumServiceClient albumServiceClient) {
        this.environment = environment;
        this.userUseCase = userUseCase;
        this.userWebMapper = userWebMapper;
        this.jwtTokenUtil = jwtTokenUtil;
        this.albumServiceClient = albumServiceClient;
    }

    @GetMapping("/status/check")
    public String status() {
        return "Users Service is running on port " + environment.getProperty("local.server.port");
    }

    @GetMapping("/validate/{userId}")
    public ResponseEntity<UserResponse> validateToken(@RequestHeader("Authorization") String token, @PathVariable Long userId) {
        try {
            String jwtToken = token.substring(7); // Remove "Bearer "
//            String email = jwtTokenUtil.getUsernameFromToken(jwtToken);
//            List<String> roles = jwtTokenUtil.getRolesFromToken(jwtToken);

            var user = userUseCase.findUserById(userId).orElseThrow();

            if (jwtTokenUtil.validateToken(jwtToken, user.email())) {
                return ResponseEntity.ok(userWebMapper.fromDomain(user));
            }
        } catch (Exception e) {
            return ResponseEntity.status(401).build();
        }
        return ResponseEntity.status(401).build();
    }


    @PostMapping
    public ResponseEntity<UserResponse> createUser(@RequestBody UserRequest request) {
        User user = userWebMapper.toDomain(request);
        User createdUser = userUseCase.createUser(user);
        return new ResponseEntity<>(userWebMapper.fromDomain(createdUser), HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<UserResponse>> findAllUser() {
        // User user = UserWebMapper.toDomain(request);
        List<User> users = userUseCase.findAllUser();
        return new ResponseEntity<>(users.stream().map(userWebMapper::fromDomain).toList(), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDetailResponse> getUserDetails(@RequestHeader("Authorization") String token, @PathVariable("id") Long id) {

        log.debug("Before calling album service with token: {}", token);
        final User user = userUseCase.findUserById(id).orElseThrow();
        final UserResponse userResponse = userWebMapper.fromDomain(user);
        List<AlbumResponse> albumResponses =  albumServiceClient.getAlbums(token, id);
        log.debug("After calling album service, received {} albums for user id: {}", albumResponses.size(), id);

        return new ResponseEntity<>(UserDetailResponse.builder()
                .id(userResponse.id())
                .email(userResponse.email())
                .firstname(userResponse.firstname())
                .lastname(userResponse.lastname())
                .albums(albumResponses)
                .build(), HttpStatus.OK);
    }
}
