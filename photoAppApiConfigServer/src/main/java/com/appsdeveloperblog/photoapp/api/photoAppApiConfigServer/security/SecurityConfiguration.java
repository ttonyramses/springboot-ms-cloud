package com.appsdeveloperblog.photoapp.api.photoAppApiConfigServer.security;


import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Objects;

@Configuration
@EnableWebSecurity
public class SecurityConfiguration {

    private final Environment environment;

    public SecurityConfiguration(Environment environment) {
        this.environment = environment;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(authz -> authz
                        // Endpoints d'administration
                        .requestMatchers(HttpMethod.POST, "/actuator/busrefresh").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/encrypt").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/decrypt").hasRole("ADMIN")
                        .requestMatchers("/actuator/**").hasRole("USER")
                        // Toutes les autres requêtes nécessitent une authentification
                        .anyRequest().authenticated())
                .csrf(csrfCustomizer -> csrfCustomizer.ignoringRequestMatchers(
                        "/actuator/busrefresh", "/encrypt", "/decrypt"))
                .httpBasic(Customizer.withDefaults());
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails admin = User.builder()
                .username(Objects.requireNonNull(environment.getProperty("spring.security.user.name")))
                .password(passwordEncoder().encode(Objects.requireNonNull(environment.getProperty("spring.security.user.password"))))
                .roles(Objects.requireNonNull(environment.getProperty("spring.security.user.roles")))
                .build();
        UserDetails user = User.builder()
                .username(Objects.requireNonNull(environment.getProperty("spring.security.user1.name")))
                .password(passwordEncoder().encode(Objects.requireNonNull(environment.getProperty("spring.security.user1.password"))))
                .roles(Objects.requireNonNull(environment.getProperty("spring.security.user1.roles")))
                .build();

        return new InMemoryUserDetailsManager(admin, user);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}