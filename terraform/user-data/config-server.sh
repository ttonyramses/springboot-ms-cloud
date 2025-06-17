#!/bin/bash
# user-data/config-server.sh
# Script d'installation pour Config Server + RabbitMQ

set -e

# Variables (passées par Terraform)
#ENVIRONMENT="${ENVIRONMENT}"
#PROJECT="${PROJECT}"
#DB_ENDPOINT="${DB_ENDPOINT}"
LOG_FILE="/var/log/user-data.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "=== Installation Config Server + RabbitMQ ==="
log "Environment: $ENVIRONMENT"
log "Project: $PROJECT"
log "DB Endpoint: $DB_ENDPOINT"

# Exécuter le script de base d'abord
source /tmp/base-setup.sh

# Installation de RabbitMQ
log "Installation de RabbitMQ..."
apt-get update -y

# Ajouter le repository RabbitMQ
curl -fsSL https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA | gpg --dearmor | tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null
curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf77f1eda57ebb1cc | gpg --dearmor | tee /usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg > /dev/null
curl -fsSL https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey | gpg --dearmor | tee /usr/share/keyrings/io.packagecloud.rabbitmq.gpg > /dev/null

# Ajouter les sources
cat > /etc/apt/sources.list.d/rabbitmq.list << 'EOF'
deb [signed-by=/usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu jammy main
deb-src [signed-by=/usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu jammy main
deb [signed-by=/usr/share/keyrings/io.packagecloud.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ jammy main
deb-src [signed-by=/usr/share/keyrings/io.packagecloud.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ jammy main
EOF

# Installer RabbitMQ
apt-get update -y
apt-get install -y erlang-base \
    erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
    erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
    erlang-runtime-tools erlang-snmp erlang-ssl \
    erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl

apt-get install -y rabbitmq-server

# Démarrer et activer RabbitMQ
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Attendre que RabbitMQ soit prêt
sleep 10

# Activer le plugin de management
rabbitmq-plugins enable rabbitmq_management

# Créer un utilisateur admin
rabbitmqctl add_user admin admin123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

# Redémarrer RabbitMQ
systemctl restart rabbitmq-server

log "RabbitMQ installé et configuré"

# Configuration du Config Server avec Docker
log "Configuration du Config Server..."

# Créer le répertoire pour le Config Server
mkdir -p /opt/microservices/config-server
mkdir -p /opt/microservices/config-repo

# Créer un repository git local pour les configurations
cd /opt/microservices/config-repo
git init
git config user.name "Config Server"
git config user.email "config@microservices.local"

# Créer les fichiers de configuration pour chaque service
cat > application.yml << EOF
spring:
  datasource:
    url: jdbc:postgresql://$DB_ENDPOINT:5432/microservicesdb
    username: postgres
    password: \$${DB_PASSWORD:changeme}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect

  rabbitmq:
    host: localhost
    port: 5672
    username: admin
    password: admin123

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
    org.springframework.cloud: DEBUG
    org.springframework.web: DEBUG
  file:
    name: /var/log/microservices/application.log

eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-server:8761/eureka/
  instance:
    preferIpAddress: true
EOF

# Configuration spécifique pour l'API Gateway
cat > api-gateway.yml << EOF
server:
  port: 8080

spring:
  cloud:
    gateway:
      routes:
        - id: users-service
          uri: lb://users-service
          predicates:
            - Path=/users/**
        - id: albums-service
          uri: lb://albums-service
          predicates:
            - Path=/albums/**
      globalcors:
        corsConfigurations:
          '[/**]':
            allowedOrigins: "*"
            allowedMethods: "*"
            allowedHeaders: "*"

management:
  endpoints:
    web:
      exposure:
        include: "*"
EOF

# Configuration pour Users Service
cat > users-service.yml << EOF
server:
  port: 8081

spring:
  application:
    name: users-service
  datasource:
    url: jdbc:postgresql://$DB_ENDPOINT:5432/microservicesdb
    username: postgres
    password: \$${DB_PASSWORD:changeme}
EOF

# Configuration pour Albums Service
cat > albums-service.yml << EOF
server:
  port: 8082

spring:
  application:
    name: albums-service
  datasource:
    url: jdbc:postgresql://$DB_ENDPOINT:5432/microservicesdb
    username: postgres
    password: \$${DB_PASSWORD:changeme}
EOF

# Committer les configurations
git add .
git commit -m "Initial configuration"

log "Repository de configuration créé"

# Créer le docker-compose pour le Config Server
cat > /opt/microservices/config-server/docker-compose.yml << EOF
version: '3.8'

services:
  config-server:
    image: openjdk:21-jdk-slim
    container_name: config-server
    ports:
      - "8888:8888"
    environment:
      - SPRING_PROFILES_ACTIVE=native
      - SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS=file:///config-repo
      - SPRING_CLOUD_CONFIG_SERVER_GIT_URI=file:///config-repo
    volumes:
      - /opt/microservices/config-repo:/config-repo:ro
      - /opt/microservices/config-server/app.jar:/app.jar:ro
    command: ["java", "-jar", "/app.jar"]
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8888/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - microservices-network

networks:
  microservices-network:
    driver: bridge
EOF

# Créer un script de démarrage pour le Config Server
cat > /opt/microservices/config-server/start.sh << 'EOF'
#!/bin/bash
set -e

echo "Démarrage du Config Server..."

# Attendre que RabbitMQ soit prêt
while ! nc -z localhost 5672; do
    echo "Attente de RabbitMQ..."
    sleep 2
done

echo "RabbitMQ est prêt, démarrage du Config Server..."

# Note: En attendant le JAR de l'application, on crée un serveur simple
# Dans un vrai déploiement, vous devriez copier votre JAR ici

# Pour l'instant, on démarre juste un conteneur de test
docker run -d \
    --name config-server-simple \
    --network host \
    -e SPRING_PROFILES_ACTIVE=native \
    -e SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS=file:///config \
    -v /opt/microservices/config-repo:/config:ro \
    -p 8888:8888 \
    springcloud/configserver:latest

echo "Config Server démarré"
EOF

chmod +x /opt/microservices/config-server/start.sh

# Créer un service systemd pour le Config Server
cat > /etc/systemd/system/config-server.service << 'EOF'
[Unit]
Description=Spring Cloud Config Server
After=docker.service rabbitmq-server.service
Requires=docker.service rabbitmq-server.service

[Service]
Type=forking
User=ubuntu
ExecStart=/opt/microservices/config-server/start.sh
ExecStop=/usr/bin/docker stop config-server-simple
ExecReload=/usr/bin/docker restart config-server-simple
TimeoutStartSec=0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer le service
systemctl daemon-reload
systemctl enable config-server

# Changer les permissions
chown -R ubuntu:ubuntu /opt/microservices

# Configuration du firewall pour RabbitMQ et Config Server
ufw allow 5672   # RabbitMQ
ufw allow 15672  # RabbitMQ Management
ufw allow 8888   # Config Server

log "=== Installation Config Server + RabbitMQ terminée ==="

# Démarrer le Config Server
systemctl start config-server

# Signal de fin d'installation
touch /tmp/config-server-setup-complete
echo "$(date '+%Y-%m-%d %H:%M:%S') - Config Server setup completed" > /tmp/config-server-status

log "Config Server disponible sur le port 8888"
log "RabbitMQ Management disponible sur le port 15672 (admin/admin123)"