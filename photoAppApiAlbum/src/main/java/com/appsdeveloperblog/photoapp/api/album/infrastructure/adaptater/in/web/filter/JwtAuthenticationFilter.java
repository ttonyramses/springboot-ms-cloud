package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.filter;

import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.dto.UserResponse;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.security.JwtTokenUtil;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.service.UserServiceClient;
import io.jsonwebtoken.ExpiredJwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtTokenUtil jwtTokenUtil;

    @Autowired
    private UserServiceClient userServiceClient;

    private static final Pattern USER_ID_PATTERN = Pattern.compile("/api/users/(\\d+)/");

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        final String requestTokenHeader = request.getHeader("Authorization");
        final String requestPath = request.getRequestURI();

        String username = null;
        String jwtToken = null;

        if (requestTokenHeader != null && requestTokenHeader.startsWith("Bearer ")) {
            jwtToken = requestTokenHeader.substring(7);
            try {
                username = jwtTokenUtil.getUsernameFromToken(jwtToken);
            } catch (IllegalArgumentException e) {
                 log.error("Unable to get JWT Token");
            } catch (ExpiredJwtException e) {
                 log.error("JWT Token has expired");
            }
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {

            Long userId  = extractUserIdFromUrl(requestPath);
            // Valider le token avec le service User
            UserResponse userInfo = userServiceClient.validateToken("Bearer " + jwtToken, userId);

            if (userInfo != null) {
                //  CustomUserDetails userDetails = new CustomUserDetails(userInfo);
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(userInfo, null, List.of());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }
        chain.doFilter(request, response);
    }

    /**
     * Extrait l'ID utilisateur depuis l'URL
     * Exemples:
     * - /api/users/123/albums → 123
     * - /api/users/456/albums/789 → 456
     */
    private Long extractUserIdFromUrl(String requestPath) {
        if (requestPath == null) {
            return null;
        }

        Matcher matcher = USER_ID_PATTERN.matcher(requestPath);
        if (matcher.find()) {
            var userIdGroup = "";
            try {
                userIdGroup = matcher.group(1);
                return Long.parseLong(userIdGroup);
            } catch (NumberFormatException e) {
                 log.warn("Invalid user ID format in URL: {}", userIdGroup);
                return null;
            }
        }

        return null;
    }
}


