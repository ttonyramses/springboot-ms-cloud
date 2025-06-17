package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.filter;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.LoginRequest;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security.JwtTokenUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.io.IOException;
import java.util.ArrayList;

public class AuthentificationFilter extends UsernamePasswordAuthenticationFilter {

    private final UserUseCase userUseCase;
    private final JwtTokenUtil jwtTokenUtil;

    public AuthentificationFilter(AuthenticationManager authenticationManager, UserUseCase userUseCase, JwtTokenUtil jwtTokenUtil) {
        super(authenticationManager);
        this.userUseCase = userUseCase;
        this.jwtTokenUtil = jwtTokenUtil;
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

         UserDetails userDetails = (UserDetails) authResult.getPrincipal();
        String email =  userDetails.getUsername();
        User user = userUseCase.findUserByEmail(email).orElseThrow(()->new UsernameNotFoundException("User not found with email: " + email));;
        String token = jwtTokenUtil.generateToken(user);
        response.addHeader("jwt-token", token);

        // ✅ Retourner dans le body JSON
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String json = String.format("""
        {
            "jwtToken": "%s",
        }
        """, token);

        response.getWriter().write(json);
        response.getWriter().flush();

    }



    }