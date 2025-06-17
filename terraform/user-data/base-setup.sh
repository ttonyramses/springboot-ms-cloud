#!/bin/bash
# user-data/base-setup.sh
# Script de base pour toutes les instances EC2

set -e

# Variables
# Variables injectées par Terraform
#export ENVIRONMENT="${ENVIRONMENT}"
#export PROJECT="${PROJECT}"
#export REGION="${REGION}"

LOG_FILE="/var/log/user-data.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "=== Début de l'installation de base ==="
log "Environment: $ENVIRONMENT"
log "Project: $PROJECT"
log "Region: $REGION"

# Mise à jour du système
log "Mise à jour du système..."
apt-get update -y
apt-get upgrade -y

# Installation des packages de base
log "Installation des packages de base..."
apt-get install -y \
    wget \
    curl \
    unzip \
    vim \
    htop \
    tree \
    jq \
    git \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Installation de Java 21
log "Installation de Java 21..."
apt-get install -y openjdk-21-jdk

# Configuration des variables d'environnement Java
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment
source /etc/environment

# Vérification de Java
log "Vérification de Java..."
java -version 2>&1 | tee -a $LOG_FILE

# Installation de Docker
log "Installation de Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrage et activation de Docker
systemctl start docker
systemctl enable docker

# Ajout de l'utilisateur ubuntu au groupe docker
usermod -aG docker ubuntu

# Installation de Docker Compose
log "Installation de Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Installation d'AWS CLI
log "Installation d'AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Installation de CloudWatch Agent
log "Installation de CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Installation de Session Manager Plugin
log "Installation de Session Manager Plugin..."
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
dpkg -i session-manager-plugin.deb
rm session-manager-plugin.deb

# Configuration du timezone
log "Configuration du timezone..."
timedatectl set-timezone Europe/Paris

# Création des répertoires de travail
log "Création des répertoires de travail..."
mkdir -p /opt/microservices
mkdir -p /var/log/microservices
mkdir -p /etc/microservices

# Configuration des permissions
chown -R ubuntu:ubuntu /opt/microservices
chown -R ubuntu:ubuntu /var/log/microservices
chmod 755 /var/log/microservices

# Installation de Filebeat pour les logs
log "Installation de Filebeat..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update -y
apt-get install -y filebeat

# Configuration basique de Filebeat
cat > /etc/filebeat/filebeat.yml << 'EOF'
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/microservices/*.log
  fields:
    environment: ${ENVIRONMENT}
    project: ${PROJECT}
    service: microservice
  fields_under_root: true

output.logstash:
  hosts: ["localhost:5044"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
EOF

# Activation de Filebeat
systemctl enable filebeat

# Configuration du monitoring système
log "Configuration du monitoring système..."
cat > /etc/microservices/system-monitor.sh << 'EOF'
#!/bin/bash
# Script de monitoring système

# Métriques système
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
DISK_USAGE=$(df -h / | awk 'NR==2{printf "%s", $5}' | sed 's/%//')

# Log des métriques
echo "$(date) - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%" >> /var/log/microservices/system-metrics.log

# Alertes basiques
if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
    echo "$(date) - ALERT: High CPU usage: ${CPU_USAGE}%" >> /var/log/microservices/alerts.log
fi

if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    echo "$(date) - ALERT: High Memory usage: ${MEMORY_USAGE}%" >> /var/log/microservices/alerts.log
fi

if (( DISK_USAGE > 90 )); then
    echo "$(date) - ALERT: High Disk usage: ${DISK_USAGE}%" >> /var/log/microservices/alerts.log
fi
EOF

chmod +x /etc/microservices/system-monitor.sh

# Ajout d'une tâche cron pour le monitoring
echo "*/5 * * * * /etc/microservices/system-monitor.sh" | crontab -u ubuntu -

# Configuration du pare-feu basique
log "Configuration du pare-feu basique..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 10.0.0.0/16

# Configuration de logrotate pour les logs des microservices
log "Configuration de logrotate..."
cat > /etc/logrotate.d/microservices << 'EOF'
/var/log/microservices/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload filebeat
    endscript
}
EOF

# Installation de packages de monitoring
log "Installation de packages de monitoring..."
apt-get install -y \
    netstat-nat \
    iotop \
    iftop \
    nethogs \
    dstat \
    ncdu

# Configuration des alias utiles
log "Configuration des alias utiles..."
cat >> /home/ubuntu/.bashrc << EOF

# Alias personnalisés pour les microservices
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias logs='tail -f /var/log/microservices/*.log'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'

# Variables d'environnement
export ENVIRONMENT=$ENVIRONMENT
export PROJECT=$PROJECT
export REGION=$REGION
EOF

# Configuration SSH pour l'utilisateur ubuntu
log "Configuration SSH..."
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh

# Configuration de motd personnalisé
log "Configuration du message d'accueil..."
cat > /etc/motd << EOF
================================================================================
  🚀 $PROJECT - $ENVIRONMENT Environment
================================================================================

  Instance Type: \$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
  Instance ID:   \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  Private IP:    \$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
  Region:        $REGION

  Useful Commands:
    - logs          : Voir les logs des microservices
    - dps           : Voir les containers Docker
    - systemctl status [service] : Statut d'un service

  Log Locations:
    - Application:  /var/log/microservices/
    - System:       /var/log/syslog
    - Docker:       docker logs [container_name]

================================================================================
EOF

# Nettoyage final
log "Nettoyage final..."
apt-get autoremove -y
apt-get autoclean

# Redémarrage des services nécessaires
log "Redémarrage des services..."
systemctl restart cron
systemctl restart rsyslog

log "=== Installation de base terminée avec succès ==="
log "Java version: $(java -version 2>&1 | head -n 1)"
log "Docker version: $(docker --version)"
log "AWS CLI version: $(aws --version)"

# Signal de fin d'installation
touch /tmp/base-setup-complete
echo "$(date '+%Y-%m-%d %H:%M:%S') - Base setup completed successfully" > /tmp/setup-status
