#!/bin/bash
# user-data/eureka-server.sh
# Script d'installation pour Eureka Server

set -e

# Variables (passées par Terraform)
#ENVIRONMENT="${environment}"
#PROJECT="${project}"
LOG_FILE="/var/log/user-data.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "=== Installation Eureka Server ==="
log "Environment: $ENVIRONMENT"
log "Project: $PROJECT"

# Exécuter le script de base d'abord
source /tmp/base-setup.sh

# Configuration d'Eureka Server avec Docker
log "Configuration d'Eureka Server..."

# Créer le répertoire pour Eureka Server
mkdir -p /opt/microservices/eureka-server
cd /opt/microservices/eureka-server

# Créer la configuration application.yml pour Eureka
cat > application.yml << EOF
server:
  port: 8761

spring:
  application:
    name: eureka-server

eureka:
  instance:
    hostname: eureka-server
    preferIpAddress: true
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://\${eureka.instance.hostname}:\${server.port}/eureka/
  server:
    enableSelfPreservation: false
    evictionIntervalTimerInMs: 10000

management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always

logging:
  level:
    com.netflix.eureka: INFO
    com.netflix.discovery: INFO
  file:
    name: /var/log/microservices/eureka-server.log
EOF

# Créer le docker-compose pour Eureka Server
cat > docker-compose.yml << EOF
version: '3.8'

services:
  eureka-server:
    image: springcloud/eureka:latest
    container_name: eureka-server
    ports:
      - "8761:8761"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - EUREKA_INSTANCE_HOSTNAME=eureka-server
      - EUREKA_CLIENT_REGISTER_WITH_EUREKA=false
      - EUREKA_CLIENT_FETCH_REGISTRY=false
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://eureka-server:8761/eureka/
      - EUREKA_SERVER_ENABLE_SELF_PRESERVATION=false
    volumes:
      - ./application.yml:/application.yml:ro
      - /var/log/microservices:/var/log/microservices
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8761/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    networks:
      - microservices-network

networks:
  microservices-network:
    driver: bridge
EOF

# Créer un script de démarrage simple avec Java directement
cat > start-eureka.sh << 'EOF'
#!/bin/bash
set -e

echo "Démarrage d'Eureka Server..."

# Créer un JAR Eureka simple avec Spring Boot
# En attendant le vrai JAR, on utilise l'image Docker standard

docker-compose up -d

echo "Eureka Server démarré sur le port 8761"

# Attendre qu'Eureka soit prêt
echo "Attente qu'Eureka soit prêt..."
for i in {1..30}; do
    if curl -f http://localhost:8761/actuator/health >/dev/null 2>&1; then
        echo "Eureka Server est prêt!"
        break
    fi
    echo "Tentative $i/30..."
    sleep 10
done
EOF

chmod +x start-eureka.sh

# Alternative: Créer un JAR Eureka simple si Docker n'est pas disponible
log "Création d'un serveur Eureka alternatif..."

# Créer un projet Spring Boot simple
mkdir -p src/main/java/com/microservices/eureka
mkdir -p src/main/resources

# Créer la classe principale
cat > src/main/java/com/microservices/eureka/EurekaServerApplication.java << 'EOF'
package com.microservices.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
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
    <artifactId>eureka-server</artifactId>
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
            <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>\${spring-cloud.version}</version>
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

# Installer Maven si nécessaire
log "Installation de Maven..."
apt-get install -y maven

# Créer un service systemd pour Eureka
cat > /etc/systemd/system/eureka-server.service << 'EOF'
[Unit]
Description=Eureka Server
After=network.target docker.service
Wants=docker.service

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/opt/microservices/eureka-server
ExecStart=/opt/microservices/eureka-server/start-eureka.sh
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=120
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

# Activer le service
systemctl daemon-reload
systemctl enable eureka-server

# Changer les permissions
chown -R ubuntu:ubuntu /opt/microservices

# Configuration du firewall pour Eureka
ufw allow 8761

log "=== Installation Eureka Server terminée ==="

# Démarrer Eureka Server
systemctl start eureka-server

# Signal de fin d'installation
touch /tmp/eureka-server-setup-complete
echo "$(date '+%Y-%m-%d %H:%M:%S') - Eureka Server setup completed" > /tmp/eureka-server-status

log "Eureka Server disponible sur le port 8761"
log "Dashboard Eureka: http://<server-ip>:8761"