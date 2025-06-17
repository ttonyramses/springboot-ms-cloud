package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.security;

import com.appsdeveloperblog.photoapp.api.album.infrastructure.configuration.ApplicationConfiguration;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.impl.lang.Function;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.List;

@Component
public class JwtTokenUtil {

    private final ApplicationConfiguration applicationConfiguration;
    private final JwtParser jwtParser;
    private final SecretKey secretKey;

    public JwtTokenUtil(ApplicationConfiguration applicationConfiguration) {
        this.applicationConfiguration = applicationConfiguration;

        byte[] keyBytes = java.util.Base64.getDecoder().decode(applicationConfiguration.getToken().getSecret());
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        this.jwtParser = Jwts.parser()
                .verifyWith(secretKey)  // Remplace setSigningKey
                .build();
    }

    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    public Long getUserIdFromToken(String token) {
        return getClaimFromToken(token, claims ->((Integer)claims.get("userId")).longValue());
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
