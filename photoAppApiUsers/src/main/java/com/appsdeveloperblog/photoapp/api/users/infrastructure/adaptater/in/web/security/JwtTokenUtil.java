package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security;

import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.configuration.ApplicationConfiguration;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.impl.lang.Function;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class JwtTokenUtil {

    private final ApplicationConfiguration applicationConfiguration;
    private final JwtParser jwtParser;
    private final SecretKey secretKey;
    private final Long expirationTime;

    public JwtTokenUtil(ApplicationConfiguration applicationConfiguration) {
        this.applicationConfiguration = applicationConfiguration;

        byte[] keyBytes = java.util.Base64.getDecoder().decode(applicationConfiguration.getToken().getSecret());
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        this.expirationTime = applicationConfiguration.getToken().getExpirationTime();
        this.jwtParser = Jwts.parser()
                .verifyWith(secretKey)  // Remplace setSigningKey
                .build();
    }

    public String generateToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.id());
        claims.put("email", user.email());
        claims.put("firstname", user.firstname());
        claims.put("lastname", user.lastname());
        claims.put("roles", List.of());
//        claims.put("roles", userDetails.getAuthorities().stream()
//                .map(GrantedAuthority::getAuthority)
//                .collect(Collectors.toList()));

        return createToken(claims, user.email());
    }

    private String createToken(Map<String, Object> claims, String subject) {
        Instant now = Instant.now();
        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(expirationTime)))
                .signWith(secretKey, Jwts.SIG.HS512)
                .compact();

    }

    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    public Long getUserIdFromToken(String token) {
        return getClaimFromToken(token, claims -> Long.parseLong((String) claims.get("userId")));
    }


    public List<String> getRolesFromToken(String token) {
        return getClaimFromToken(token, claims -> (List<String>) claims.get("roles"));
    }

    public boolean validateToken(String token, String expectedSubject) {
        try {
            Claims claims = getAllClaimsFromToken(token); //la valication de la date d'expiration est déjà faite
            var actualSubject = claims.getSubject();
            return expectedSubject != null && expectedSubject.equals(actualSubject);
        } catch (Exception e) {
            return false;
        }
    }


    private <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = getAllClaimsFromToken(token);
        return claimsResolver.apply(claims);
    }

    private Claims getAllClaimsFromToken(String token) {
        return jwtParser.parseSignedClaims(token).getPayload();


    }


}
