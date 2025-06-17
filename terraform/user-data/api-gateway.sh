#!/bin/bash
# user-data/api-gateway.sh
# Script d'installation pour API Gateway

set -e

# Variables (passées par Terraform)
ENVIRONMENT="${environment}"
PROJECT="${project}"
EUREKA_ENDPOINT="${eureka_endpoint}"
CONFIG_ENDPOINT="${config_endpoint}"
LOG_FILE="/var/log/user-data.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "=== Installation API Gateway ==="
log "Environment: $ENVIRONMENT"
log "Project: $PROJECT"
log "Eureka Endpoint: $EUREKA_ENDPOINT"
log "Config Endpoint: $CONFIG_ENDPOINT"

# Exécuter le script de base d'abord
source /tmp/base-setup.sh

# Configuration de l'API Gateway avec Docker
log "Configuration de l'API Gateway..."

# Créer le répertoire pour l'API Gateway
mkdir -p /opt/microservices/api-gateway
cd /opt/microservices/api-gateway

# Créer la configuration application.yml pour l'API Gateway
cat > application.yml << EOF
server:
  port: 8080

spring:
  application:
    name: api-gateway
  cloud:
    config:
      uri: http://$CONFIG_ENDPOINT:8888
      enabled: true
      fail-fast: true
      retry:
        initial-interval: 1000
        max-attempts: 6
        multiplier: 1.1
    gateway:
      routes:
        # Route pour Users Service
        - id: users-service
          uri: lb://users-service
          predicates:
            - Path=/api/users/**
          filters:
            - RewritePath=/api/users/(?<path>.*), /\${path}
            - AddRequestHeader=X-Request-Source, api-gateway

        # Route pour Albums Service
        - id: albums-service
          uri: lb://albums-service
          predicates:
            - Path=/api/albums/**
          filters:
            - RewritePath=/api/albums/(?<path>.*), /\${path}
            - AddRequestHeader=X-Request-Source, api-gateway

        # Route pour Eureka Dashboard
        - id: eureka-server
          uri: http://$EUREKA_ENDPOINT:8761
          predicates:
            - Path=/eureka/**

        # Route pour Config Server
        - id: config-server
          uri: http://$CONFIG_ENDPOINT:8888
          predicates:
            - Path=/config/**

      # Configuration CORS globale
      globalcors:
        corsConfigurations:
          '[/**]':
            allowedOriginPatterns: "*"
            allowedMethods:
              - GET
              - POST
              - PUT
              - DELETE
              - OPTIONS
            allowedHeaders: "*"
            allowCredentials: true

      # Configuration de découverte de services
      discovery:
        locator:
          enabled: true
          lower-case-service-id: true

eureka:
  client:
    serviceUrl:
      defaultZone: http://$EUREKA_ENDPOINT:8761/eureka/
    healthcheck:
      enabled: true
    fetch-registry: true
    register-with-eureka: true
  instance:
    preferIpAddress: true
    lease-renewal-interval-in-seconds: 10
    lease-expiration-duration-in-seconds: 30

management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always
    gateway:
      enabled: true

logging:
  level:
    org.springframework.cloud.gateway: DEBUG
    org.springframework.web.reactive: DEBUG
    reactor.netty: DEBUG
  file:
    name: /var/log/microservices/api-gateway.log

# Configuration de sécurité basique
security:
  oauth2:
    resourceserver:
      jwt:
        issuer-uri: http://localhost:8080/auth/realms/microservices
EOF

# Créer le docker-compose pour l'API Gateway
cat > docker-compose.yml << EOF
version: '3.8'

services:
  api-gateway:
    image: openjdk:21-jdk-slim
    container_name: api-gateway
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_CLOUD_CONFIG_URI=http://$CONFIG_ENDPOINT:8888
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://$EUREKA_ENDPOINT:8761/eureka/
      - EUREKA_INSTANCE_PREFER_IP_ADDRESS=true
    volumes:
      - ./application.yml:/application.yml:ro
      - /var/log/microservices:/var/log/microservices
      - ./gateway-app.jar:/app.jar:ro
    command: ["java", "-jar", "/app.jar"]
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 90s
    networks:
      - microservices-network
    depends_on:
      - wait-for-eureka

  # Service d'attente pour Eureka
  wait-for-eureka:
    image: curlimages/curl:latest
    container_name: wait-for-eureka
    command: >
      sh -c "
        echo 'Attente d\'Eureka Server...'
        until curl -f http://$EUREKA_ENDPOINT:8761/actuator/health; do
          echo 'Eureka non disponible, attente...'
          sleep 10
        done
        echo 'Eureka Server est prêt!'
      "
    networks:
      - microservices-network

networks:
  microservices-network:
    driver: bridge
EOF

# Créer un projet Spring Boot pour l'API Gateway
log "Création du projet API Gateway..."

mkdir -p src/main/java/com/microservices/gateway
mkdir -p src/main/resources

# Créer la classe principale
cat > src/main/java/com/microservices/gateway/ApiGatewayApplication.java << 'EOF'
package com.microservices.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;
import org.springframework.context.annotation.Bean;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

@SpringBootApplication
@EnableEurekaClient
public class ApiGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("users-service", r -> r.path("/api/users/**")
                        .filters(f -> f.rewritePath("/api/users/(?<path>.*)", "/\${path}")
                                     .addRequestHeader("X-Request-Source", "api-gateway"))
                        .uri("lb://users-service"))
                .route("albums-service", r -> r.path("/api/albums/**")
                        .filters(f -> f.rewritePath("/api/albums/(?<path>.*)", "/\${path}")
                                     .addRequestHeader("X-Request-Source", "api-gateway"))
                        .uri("lb://albums-service"))
                .build();
    }

    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfig = new CorsConfiguration();
        corsConfig.setAllowCredentials(true);
        corsConfig.addAllowedOriginPattern("*");
        corsConfig.addAllowedMethod("*");
        corsConfig.addAllowedHeader("*");

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfig);

        return new CorsWebFilter(source);
    }
}
EOF

# Créer le pom.xml pour Maven
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.microservices</groupId>
    <artifactId>api-gateway</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.5</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>21</java.version>
        <spring-cloud.version>2022.0.4</spring-cloud.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-loadbalancer</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Copier la configuration dans resources
cp application.yml src/main/resources/

# Créer un script de démarrage
cat > start-gateway.sh << 'EOF'
#!/bin/bash
set -e

echo "Démarrage de l'API Gateway..."

# Attendre qu'Eureka soit disponible
echo "Attente d'Eureka Server..."
while ! nc -z $EUREKA_ENDPOINT 8761; do
    echo "Eureka non disponible, attente..."
    sleep 5
done

echo "Attente du Config Server..."
while ! nc -z $CONFIG_ENDPOINT 8888; do
    echo "Config Server non disponible, attente..."
    sleep 5
done

echo "Services de base prêts, démarrage de l'API Gateway..."

# Démarrer avec Docker Compose
docker-compose up -d

echo "API Gateway démarré sur le port 8080"

# Attendre que l'API Gateway soit prêt
echo "Attente que l'API Gateway soit prêt..."
for i in {1..30}; do
    if curl -f http://localhost:8080/actuator/health >/dev/null 2>&1; then
        echo "API Gateway est prêt!"
        break
    fi
    echo "Tentative $i/30..."
    sleep 10
done
EOF

chmod +x start-gateway.sh

# Créer un script de build Maven
cat > build.sh << 'EOF'
#!/bin/bash
set -e

echo "Build de l'API Gateway..."

# Installer Maven si nécessaire
if ! command -v mvn &> /dev/null; then
    echo "Installation de Maven..."
    apt-get update
    apt-get install -y maven
fi

# Build du projet
mvn clean package -DskipTests

# Copier le JAR généré
if [ -f target/api-gateway-1.0.0.jar ]; then
    cp target/api-gateway-1.0.0.jar gateway-app.jar
    echo "JAR créé: gateway-app.jar"
else
    echo "Erreur: JAR non trouvé après le build"
    exit 1
fi
EOF

chmod +x build.sh

# Créer un service systemd pour l'API Gateway
cat > /etc/systemd/system/api-gateway.service << 'EOF'
[Unit]
Description=API Gateway
After=network.target docker.service
Wants=docker.service
Requires=eureka-server.service config-server.service

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/opt/microservices/api-gateway
ExecStartPre=/bin/sleep 30
ExecStart=/opt/microservices/api-gateway/start-gateway.sh
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=180
Restart=always
RestartSec=20

[Install]
WantedBy=multi-user.target
EOF

# Créer un script de health check
cat > health-check.sh << 'EOF'
#!/bin/bash

# Health check pour l'API Gateway
echo "=== Health Check API Gateway ==="

# Vérifier si le service est en cours d'exécution
if docker ps | grep -q api-gateway; then
    echo "✅ Container API Gateway en cours d'exécution"
else
    echo "❌ Container API Gateway non trouvé"
    exit 1
fi

# Vérifier la santé de l'application
if curl -f http://localhost:8080/actuator/health >/dev/null 2>&1; then
    echo "✅ API Gateway répond aux requêtes health"
else
    echo "❌ API Gateway ne répond pas"
    exit 1
fi

# Vérifier la connexion à Eureka
if curl -f http://localhost:8080/actuator/info >/dev/null 2>&1; then
    echo "✅ API Gateway actuator accessible"
else
    echo "⚠️  Actuator non accessible"
fi

echo "=== Health Check terminé ==="
EOF

chmod +x health-check.sh

# Créer un script de démarrage alternatif avec JAR natif
cat > start-native.sh << 'EOF'
#!/bin/bash
set -e

echo "Démarrage natif de l'API Gateway..."

# Variables d'environnement
export SPRING_PROFILES_ACTIVE=native
export SPRING_CLOUD_CONFIG_URI=http://$CONFIG_ENDPOINT:8888
export EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://$EUREKA_ENDPOINT:8761/eureka/

# Attendre les services requis
echo "Attente des services requis..."
./wait-for-services.sh

# Démarrer l'application
if [ -f gateway-app.jar ]; then
    echo "Démarrage avec le JAR compilé..."
    nohup java -jar gateway-app.jar > /var/log/microservices/api-gateway.log 2>&1 &
    echo $! > /tmp/api-gateway.pid
else
    echo "JAR non trouvé, building..."
    ./build.sh
    nohup java -jar gateway-app.jar > /var/log/microservices/api-gateway.log 2>&1 &
    echo $! > /tmp/api-gateway.pid
fi

echo "API Gateway démarré (PID: $(cat /tmp/api-gateway.pid))"
EOF

chmod +x start-native.sh

# Créer un script d'attente des services
cat > wait-for-services.sh << 'EOF'
#!/bin/bash

echo "Attente d'Eureka Server sur $EUREKA_ENDPOINT:8761..."
while ! nc -z $EUREKA_ENDPOINT 8761; do
    sleep 2
done
echo "✅ Eureka Server prêt"

echo "Attente du Config Server sur $CONFIG_ENDPOINT:8888..."
while ! nc -z $CONFIG_ENDPOINT 8888; do
    sleep 2
done
echo "✅ Config Server prêt"

echo "Tous les services requis sont disponibles"
EOF

chmod +x wait-for-services.sh

# Activer le service
systemctl daemon-reload
systemctl enable api-gateway

# Changer les permissions
chown -R ubuntu:ubuntu /opt/microservices

# Configuration du firewall pour l'API Gateway
ufw allow 8080

# Installer netcat pour les checks de connexion
apt-get install -y netcat-openbsd

log "=== Installation API Gateway terminée ==="

# Note: Le service sera démarré après Eureka et Config Server
log "L'API Gateway sera démarré automatiquement après les services requis"

# Signal de fin d'installation
touch /tmp/api-gateway-setup-complete
echo "$(date '+%Y-%m-%d %H:%M:%S') - API Gateway setup completed" > /tmp/api-gateway-status

log "API Gateway sera disponible sur le port 8080"
log "Routes configurées:"
log "  - /api/users/** -> users-service"
log "  - /api/albums/** -> albums-service"
log "  - /eureka/** -> eureka-server"


