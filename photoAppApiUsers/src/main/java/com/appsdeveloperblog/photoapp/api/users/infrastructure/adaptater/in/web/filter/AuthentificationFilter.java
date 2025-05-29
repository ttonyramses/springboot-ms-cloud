package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.filter;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.LoginRequest;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security.JwtUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.env.Environment;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.UUID;

public class AuthentificationFilter extends UsernamePasswordAuthenticationFilter {

    private final UserUseCase userUseCase;
    private final Environment environment;

    public AuthentificationFilter(AuthenticationManager authenticationManager, UserUseCase userUseCase, Environment environment) {
        super(authenticationManager);
        this.userUseCase = userUseCase;
        this.environment = environment;
    }
    @Override
    public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) throws AuthenticationException {

        try {
            LoginRequest loginRequest = new ObjectMapper().readValue(request.getInputStream(), LoginRequest.class);

            return getAuthenticationManager().authenticate(new UsernamePasswordAuthenticationToken(loginRequest.email(), loginRequest.password(), new ArrayList<>()));
        } catch ( IOException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    protected void successfulAuthentication(HttpServletRequest request, HttpServletResponse response, FilterChain chain,
                                            Authentication authResult) throws IOException, ServletException {

       String email =  ((UserDetails)authResult.getPrincipal()).getUsername();
        User user = userUseCase.findUserByEmail(email).orElseThrow(()->new UsernameNotFoundException("User not found with email: " + email));;
        String tokenSecret = environment.getProperty("token.secret");
        Long expirationTime = environment.getProperty("token.expiration.time", Long.class, 1800L);

        JwtUtil jwtUtil = new JwtUtil(tokenSecret, expirationTime);


        String token = jwtUtil.generateToken(user.email());
        response.addHeader("token", token);
        response.addHeader("userId", UUID.randomUUID().toString());

    }



    }