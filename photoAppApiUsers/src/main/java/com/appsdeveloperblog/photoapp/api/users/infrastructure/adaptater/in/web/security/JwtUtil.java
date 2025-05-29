package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.Date;

public class JwtUtil {

    private final SecretKey secretKey;
    private final Long expirationTime;
    private final JwtParser jwtParser;

    public JwtUtil(String base64EncodedSecretString, Long expirationTime) {
        byte[] keyBytes = java.util.Base64.getDecoder().decode(base64EncodedSecretString);
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        this.expirationTime = expirationTime;

        // Créer le parser une fois pour toutes
        this.jwtParser = Jwts.parser()
                .verifyWith(secretKey)  // Remplace setSigningKey
                .build();
    }

    public String generateToken(String subject) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(subject)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(expirationTime))) // 24 heures
                .signWith(secretKey, Jwts.SIG.HS512)
                .compact();
    }

    public String extractSubject(String token) {
        Claims claims = jwtParser.parseSignedClaims(token).getPayload();
        return claims.getSubject();
    }

    public boolean isTokenValid(String token, String expectedSubject) {
        try {
            String actualSubject = extractSubject(token); //la valication de la date d'expiration est déjà faite
            return expectedSubject.equals(actualSubject);
        } catch (Exception e) {
            return false;
        }
    }
}
