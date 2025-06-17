package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.security;

import feign.Logger;
import feign.Request;
import feign.Response;
import feign.codec.ErrorDecoder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;


@Configuration
public class FeignGobalConfig {
    @Bean
    public Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;  // Log complet pour debug
    }

    @Bean
    public Request.Options requestOptions() {
        return new Request.Options(
                2000, TimeUnit.MILLISECONDS,  // Timeout connexion
                5000, TimeUnit.MILLISECONDS,  // Timeout lecture
                true                          // Suivre les redirections
        );
    }

    // Bean pour le service Album
    @Bean("albumServiceErrorDecoder")
    public ErrorDecoder albumServiceErrorDecoder() {
        return new ServiceErrorDecoder("album-ws");
    }

    @Slf4j
    // Décodeur d'erreurs personnalisé
    static class ServiceErrorDecoder implements ErrorDecoder {

        private final ErrorDecoder defaultDecoder = new Default();
        private final String serviceName;

        public ServiceErrorDecoder(String serviceName) {
            this.serviceName = serviceName;
        }


        @Override
        public Exception decode(String methodKey, Response response) {
            log.error("🔴 Erreur API {} Service - Status: {}, Method: {}",
                    serviceName,  response.status(), methodKey);

            switch (response.status()) {
                case 400:
                    return new ServiceBadRequestException(
                            "Requête invalide vers le service "+serviceName);

                case 401:
                    return new ServiceUnauthorizedException(
                            "Token d'authentification invalide ou expiré");

                case 403:
                    return new ServiceForbiddenException(
                            "Accès refusé au service "+serviceName);

                case 404:
                    return new javax.management.ServiceNotFoundException(
                            "Utilisateur ou service "+serviceName+"  non trouvé");

                case 408:
                case 504:
                    return new ServiceTimeoutException(
                            "Timeout lors de l'appel au service "+serviceName);

                case 429:
                    return new ServiceRateLimitException(
                            "Limite de taux atteinte pour le service "+serviceName);

                case 500:
                    return new ServiceInternalErrorException(
                            "Erreur interne du service "+serviceName);

                case 502:
                case 503:
                    return new ServiceUnavailableException(
                            "Service "+serviceName+" temporairement indisponible");

                default:
                    return defaultDecoder.decode(methodKey, response);
            }
        }
    }



}



// ========================================
// EXCEPTIONS PERSONNALISÉES
// ========================================

// Exception de base
abstract class ServiceException extends RuntimeException {
    public ServiceException(String message) {
        super(message);
    }

    public ServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}

// Exceptions spécifiques
class ServiceBadRequestException extends ServiceException {
    public ServiceBadRequestException(String message) { super(message); }
}

class ServiceUnauthorizedException extends ServiceException {
    public ServiceUnauthorizedException(String message) { super(message); }
}

class ServiceForbiddenException extends ServiceException {
    public ServiceForbiddenException(String message) { super(message); }
}

class ServiceNotFoundException extends ServiceException {
    public ServiceNotFoundException(String message) { super(message); }
}

class ServiceTimeoutException extends ServiceException {
    public ServiceTimeoutException(String message) { super(message); }
}

class ServiceRateLimitException extends ServiceException {
    public ServiceRateLimitException(String message) { super(message); }
}

class ServiceInternalErrorException extends ServiceException {
    public ServiceInternalErrorException(String message) { super(message); }
}

class ServiceUnavailableException extends ServiceException {
    public ServiceUnavailableException(String message) { super(message); }
}
