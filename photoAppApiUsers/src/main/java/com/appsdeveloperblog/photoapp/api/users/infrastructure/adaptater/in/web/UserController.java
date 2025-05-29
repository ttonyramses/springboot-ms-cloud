package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserRequest;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserResponse;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.mapper.UserWebMapper;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final Environment environment;
    private final UserUseCase userUseCase;
    private final UserWebMapper userWebMapper;


    public UserController(Environment environment, UserUseCase userUseCase, UserWebMapper userWebMapper) {
        this.environment = environment;
        this.userUseCase = userUseCase;
        this.userWebMapper = userWebMapper;
    }

    @GetMapping("/status")
    public String status(){
        return "Users Service is running on port "+environment.getProperty("local.server.port");
    }


    @PostMapping
    public ResponseEntity<UserResponse> createUser(@RequestBody UserRequest request) {
        User user = userWebMapper.toDomain(request);
        User createdUser = userUseCase.createUser(user);
        return new ResponseEntity<>(userWebMapper.fromDomain(createdUser),  HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<UserResponse>> findAllUser() {
       // User user = UserWebMapper.toDomain(request);
        List<User> users = userUseCase.findAllUser();
        return new ResponseEntity<>(users.stream().map(userWebMapper::fromDomain).toList(), HttpStatus.OK);
    }
}
