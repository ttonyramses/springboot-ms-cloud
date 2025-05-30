package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.filter.AuthentificationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class WebSecurityConfiguration {
    private final UserUseCase userUseCase;
    private final Environment environment;

    public WebSecurityConfiguration(UserUseCase userUseCase, Environment environment) {
        this.userUseCase = userUseCase;
        this.environment = environment;
    }


    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        AuthenticationManagerBuilder authenticationManagerBuilder =  http.getSharedObject(AuthenticationManagerBuilder.class);

        authenticationManagerBuilder.userDetailsService(userUseCase).passwordEncoder(new BCryptPasswordEncoder());
        AuthenticationManager authenticationManager = authenticationManagerBuilder.build();

        AuthentificationFilter authentificationFilter = new AuthentificationFilter(authenticationManager, userUseCase, environment);
        String loginEndpoint = environment.getProperty("login.url.path");
        authentificationFilter.setFilterProcessesUrl(loginEndpoint);

        http.csrf(AbstractHttpConfigurer::disable);
        http.authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/users/**").permitAll()
                .requestMatchers(loginEndpoint).permitAll()
                .requestMatchers("/h2-console/**").permitAll()
                .anyRequest().authenticated())
                .addFilter(authentificationFilter)
                .authenticationManager(authenticationManager)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        http.headers(headers-> headers.frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin));
        return http.build();
    }
}
