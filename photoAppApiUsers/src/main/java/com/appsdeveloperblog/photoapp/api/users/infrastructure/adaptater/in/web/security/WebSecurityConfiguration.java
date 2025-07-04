package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.filter.AuthentificationFilter;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.filter.JwtRequestFilter;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.configuration.ApplicationConfiguration;
import org.springframework.boot.actuate.web.exchanges.HttpExchangeRepository;
import org.springframework.boot.actuate.web.exchanges.InMemoryHttpExchangeRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class WebSecurityConfiguration {
    private final UserUseCase userUseCase;
    private final ApplicationConfiguration applicationConfiguration;
    private final JwtTokenUtil jwtTokenUtil;

    public WebSecurityConfiguration(UserUseCase userUseCase, ApplicationConfiguration applicationConfiguration, JwtTokenUtil jwtTokenUtil) {
        this.userUseCase = userUseCase;
        this.applicationConfiguration = applicationConfiguration;
        this.jwtTokenUtil = jwtTokenUtil;
    }


    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        AuthenticationManagerBuilder authenticationManagerBuilder =  http.getSharedObject(AuthenticationManagerBuilder.class);

        authenticationManagerBuilder.userDetailsService(userUseCase).passwordEncoder(new BCryptPasswordEncoder());
        AuthenticationManager authenticationManager = authenticationManagerBuilder.build();

        AuthentificationFilter authentificationFilter = new AuthentificationFilter(authenticationManager, userUseCase, jwtTokenUtil);
        authentificationFilter.setFilterProcessesUrl(applicationConfiguration.getLoginUrlPath());

        // Créer le filtre JWT pour les autres requêtes
        JwtRequestFilter jwtRequestFilter = new JwtRequestFilter(userUseCase, jwtTokenUtil);


        http.csrf(AbstractHttpConfigurer::disable);
        http.authorizeHttpRequests(authz -> authz
                .requestMatchers("/actuator/**").permitAll()
                .requestMatchers(applicationConfiguration.getLoginUrlPath()).permitAll()
                .requestMatchers("/h2-console/**").permitAll()
                .anyRequest().authenticated())
                // Ajouter le filtre d'authentification (pour login)
                .addFilter(authentificationFilter)
                // Ajouter le filtre JWT (pour validation des tokens)
                .addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class)
                .authenticationManager(authenticationManager)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        http.headers(headers-> headers.frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin));
        return http.build();
    }

    @Bean
    public HttpExchangeRepository httpExchangeRepository(){
        return new InMemoryHttpExchangeRepository();
    }
}
