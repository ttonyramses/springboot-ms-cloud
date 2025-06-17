# 🚀 Infrastructure Microservices avec Terraform

> Déploiement automatisé d'une architecture microservices complète sur AWS avec Terraform

## 📋 Architecture déployée

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Config Server │    │  Eureka Server  │    │   API Gateway   │
│   + RabbitMQ    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────┬─────┴─────┬─────────────────┐
         │                 │           │                 │
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Users Service  │ │ Albums Service  │ │  Elasticsearch  │
│   + Logstash    │ │   + Logstash    │ │   + Kibana      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                 │
         └─────────────────┼─────────────────┐
                           │                 │
                  ┌─────────────────┐       │
                  │   PostgreSQL    │       │
                  │      RDS        │       │
                  └─────────────────┘       │
                                           │
                  ┌─────────────────┐       │
                  │ Application LB  │───────┘
                  │     (ALB)       │
                  └─────────────────┘
```

## 🛠️ Prérequis

### Outils nécessaires
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [jq](https://stedolan.github.io/jq/) pour le parsing JSON

### Compte AWS
- Compte AWS avec permissions appropriées
- Free Tier disponible (recommandé)

## ⚡ Installation rapide

### 1. Cloner et configurer le projet
```bash
git clone <your-repo>
cd terraform-microservices

# Rendre les scripts exécutables
chmod +x scripts/*.sh
chmod +x quick-setup.sh
```

### 2. Configuration automatique
```bash
# Configuration rapide (recommandé)
./quick-setup.sh
```

## 🔑 Création de la paire de clés SSH

### Méthode 1: AWS CLI (Recommandée)
```bash
# Créer une nouvelle paire de clés
aws ec2 create-key-pair \
    --key-name microservices-dev-key \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/microservices-dev-key.pem

# Sécuriser la clé privée
chmod 400 ~/.ssh/microservices-dev-key.pem

# Vérifier que la clé a été créée
aws ec2 describe-key-pairs --key-names microservices-dev-key
```

### Méthode 2: Console AWS
1. Aller dans **EC2 > Key Pairs**
2. Cliquer sur **"Create key pair"**
3. Nom: `microservices-dev-key`
4. Type: **RSA**
5. Format: **.pem**
6. Télécharger et sauvegarder dans `~/.ssh/`

### Méthode 3: Utiliser une clé existante
```bash
# Lister vos clés existantes
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table

# Utiliser une clé existante dans terraform.tfvars
key_pair_name = "your-existing-key-name"
```

## ⚙️ Configuration

### 1. Configurer AWS CLI
```bash
# Configuration des credentials
aws configure
# AWS Access Key ID: [Votre Access Key]
# AWS Secret Access Key: [Votre Secret Key] 
# Default region name: eu-west-3
# Default output format: json

# Vérifier la configuration
aws sts get-caller-identity
```

### 2. Configurer les variables Terraform
```bash
# Copier l'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
nano terraform.tfvars
```

**Variables importantes à modifier :**
```hcl
# terraform.tfvars
key_pair_name = "microservices-dev-key"  # Votre clé SSH
db_password = "VotreMotDePasseSecurise123!"  # Mot de passe DB sécurisé

# Free Tier (économique)
instance_type = "t2.micro"
db_instance_class = "db.t3.micro"
enable_nat_gateway = false
```

## 🚀 Déploiement

### Méthode 1: Script automatique (Recommandée)
```bash
# Planifier le déploiement
./scripts/deploy.sh plan

# Appliquer les changements
./scripts/deploy.sh apply

# Voir les informations de déploiement
./scripts/deploy.sh output
```

### Méthode 2: Commandes Terraform manuelles
```bash
# Initialiser Terraform
terraform init

# Valider la configuration
terraform validate

# Planifier les changements
terraform plan -var-file="terraform.tfvars"

# Appliquer le déploiement
terraform apply -var-file="terraform.tfvars"
```

## 🔗 Accès aux services

Après le déploiement, récupérez les URLs :
```bash
# Voir toutes les informations
terraform output

# URL de l'application
terraform output application_url

# IP du bastion (pour SSH)
terraform output bastion_public_ip
```

### Connexions SSH
```bash
# Se connecter au bastion
ssh -i ~/.ssh/microservices-dev-key.pem ubuntu@<BASTION_IP>

# Tunnels SSH pour accéder aux services internes
ssh -i ~/.ssh/microservices-dev-key.pem -L 5601:10.0.10.x:5601 ubuntu@<BASTION_IP>  # Kibana
ssh -i ~/.ssh/microservices-dev-key.pem -L 8761:10.0.10.x:8761 ubuntu@<BASTION_IP>  # Eureka
ssh -i ~/.ssh/microservices-dev-key.pem -L 15672:10.0.10.x:15672 ubuntu@<BASTION_IP>  # RabbitMQ
```

## 📊 Services disponibles

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| API Gateway | 8080 | `http://<ALB_DNS>` | Point d'entrée principal |
| Eureka Dashboard | 8761 | `http://localhost:8761` (via tunnel) | Service discovery |
| Kibana | 5601 | `http://localhost:5601` (via tunnel) | Visualisation logs |
| RabbitMQ Management | 15672 | `http://localhost:15672` (via tunnel) | Gestion des messages |

## 💰 Coûts estimés

### Free Tier (12 mois)
- **6x EC2 t2.micro**: Gratuit (750h/mois)
- **RDS db.t3.micro**: Gratuit (750h/mois)
- **ALB**: ~18€/mois
- **EBS Storage**: 30GB gratuits
- **Trafic réseau**: 15GB gratuits

**Total: ~18-25€/mois**

## 🛡️ Sécurité

### Recommandations de sécurité
```bash
# Restreindre l'accès SSH (en production)
allowed_ssh_cidrs = ["VOTRE_IP/32"]

# Changer le mot de passe de la base de données
db_password = "MotDePasseTresSecurise123!"

# Activer la suppression protection (en production)
db_deletion_protection = true
enable_deletion_protection = true
```

## 🔧 Dépannage

### Erreurs communes

**Erreur: "Invalid key pair"**
```bash
# Vérifier que la clé existe
aws ec2 describe-key-pairs --key-names your-key-name

# Créer la clé si nécessaire
aws ec2 create-key-pair --key-name your-key-name --query 'KeyMaterial' --output text > ~/.ssh/your-key-name.pem
chmod 400 ~/.ssh/your-key-name.pem
```

**Erreur: "Insufficient permissions"**
```bash
# Vérifier vos permissions AWS
aws sts get-caller-identity

# Vérifier les politiques IAM attachées
aws iam list-attached-user-policies --user-name your-username
```

**Erreur: "Resource already exists"**
```bash
# Importer la ressource existante
terraform import aws_security_group.example sg-1234567890abcdef0

# Ou détruire et recréer
terraform destroy -target=aws_security_group.example
```

### Logs et debugging
```bash
# Logs Terraform détaillés
export TF_LOG=DEBUG
terraform apply

# Logs des instances EC2
ssh -i ~/.ssh/your-key.pem ubuntu@<IP> "sudo tail -f /var/log/user-data.log"

# Status des services
ssh -i ~/.ssh/your-key.pem ubuntu@<IP> "sudo systemctl status docker"
```

## 🗑️ Nettoyage

### Détruire l'infrastructure
```bash
# Via le script (avec confirmation)
./scripts/deploy.sh destroy

# Ou manuellement
terraform destroy -var-file="terraform.tfvars"

# Nettoyer les fichiers temporaires
./scripts/deploy.sh clean
```

### Supprimer la paire de clés
```bash
# Supprimer de AWS
aws ec2 delete-key-pair --key-name microservices-dev-key

# Supprimer le fichier local
rm ~/.ssh/microservices-dev-key.pem
```

## 📚 Structure du projet

```
terraform-microservices/
├── main.tf                    # Configuration principale
├── variables.tf               # Variables Terraform
├── outputs.tf                 # Sorties
├── networking.tf              # VPC, subnets, routes
├── security-groups.tf         # Groupes de sécurité
├── compute.tf                 # Instances EC2
├── database.tf                # RDS PostgreSQL
├── load-balancer.tf           # Application Load Balancer
├── terraform.tfvars           # Variables (à créer)
├── terraform.tfvars.example   # Exemple de variables
├── .gitignore                 # Fichiers à ignorer
├── README.md                  # Ce fichier
├── scripts/
│   ├── deploy.sh              # Script de déploiement
│   └── post-deploy.sh         # Configuration post-déploiement
└── user-data/
    └── base-setup.sh          # Script d'installation de base
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

- 📧 Email: support@yourcompany.com
- 📖 Documentation: [Wiki du projet](link-to-wiki)
- 🐛 Issues: [GitHub Issues](link-to-issues)

---

**Made with ❤️ for microservices architecture**