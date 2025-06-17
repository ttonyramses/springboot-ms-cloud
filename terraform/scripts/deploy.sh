#!/bin/bash
# scripts/deploy.sh
# Script de déploiement avancé pour l'infrastructure microservices

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables par défaut
ACTION=${1:-plan}
ENVIRONMENT=${2:-dev}
TERRAFORM_VARS_FILE="terraform.tfvars"
STATE_BACKUP_DIR="$PROJECT_DIR/state-backups"

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

show_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                    🚀 MICROSERVICES DEPLOYER                  ║
║                     Infrastructure as Code                    ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [ACTION] [ENVIRONMENT] [OPTIONS]

ACTIONS:
    plan        - Planifier les changements (défaut)
    apply       - Appliquer les changements
    destroy     - Détruire l'infrastructure
    validate    - Valider la configuration
    init        - Initialiser Terraform
    refresh     - Rafraîchir l'état
    output      - Afficher les outputs
    fmt         - Formater les fichiers Terraform
    state       - Gestion de l'état
    clean       - Nettoyer les fichiers temporaires

ENVIRONMENTS:
    dev         - Développement (défaut)
    staging     - Pré-production
    prod        - Production

OPTIONS:
    -f, --force         Force l'exécution sans confirmation
    -v, --verbose       Mode verbeux
    -h, --help          Afficher cette aide
    --auto-approve      Approbation automatique pour apply/destroy
    --var-file FILE     Utiliser un fichier de variables spécifique
    --target RESOURCE   Cibler une ressource spécifique
    --backup           Créer une sauvegarde avant apply/destroy

Examples:
    $0 plan dev
    $0 apply prod --auto-approve
    $0 destroy dev --backup
    $0 validate
    $0 output
EOF
}

# ============================================================================
# VÉRIFICATIONS PRÉALABLES
# ============================================================================

check_dependencies() {
    log "🔍 Vérification des dépendances..."

    local deps=("terraform" "aws" "jq")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Dépendances manquantes: ${missing_deps[*]}"
        log_info "Installez les dépendances manquantes et relancez le script"
        exit 1
    fi

    log_success "Toutes les dépendances sont installées"
}

check_aws_credentials() {
    log "🔐 Vérification des credentials AWS..."

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Credentials AWS non configurés ou invalides"
        log_info "Configurez AWS CLI avec 'aws configure' ou définissez les variables d'environnement"
        exit 1
    fi

    local identity=$(aws sts get-caller-identity)
    local account_id=$(echo "$identity" | jq -r '.Account')
    local user_arn=$(echo "$identity" | jq -r '.Arn')

    log_success "Connecté en tant que: $user_arn"
    log_info "Account ID: $account_id"
}

check_terraform_files() {
    log "📁 Vérification des fichiers Terraform..."

    cd "$TERRAFORM_DIR"

    if [ ! -f "main.tf" ]; then
        log_error "Fichier main.tf non trouvé dans $TERRAFORM_DIR"
        exit 1
    fi

    if [ ! -f "$TERRAFORM_VARS_FILE" ] && [ "$ACTION" != "init" ] && [ "$ACTION" != "validate" ]; then
        log_error "Fichier $TERRAFORM_VARS_FILE non trouvé"
        log_info "Copiez terraform.tfvars.example vers terraform.tfvars et configurez les valeurs"
        exit 1
    fi

    log_success "Fichiers Terraform trouvés"
}

check_environment() {
    log "🌍 Vérification de l'environnement..."

    case "$ENVIRONMENT" in
        dev|staging|prod)
            log_success "Environnement: $ENVIRONMENT"
            ;;
        *)
            log_error "Environnement non valide: $ENVIRONMENT"
            log_info "Environnements supportés: dev, staging, prod"
            exit 1
            ;;
    esac
}

# ============================================================================
# FONCTIONS TERRAFORM
# ============================================================================

terraform_init() {
    log "🔧 Initialisation de Terraform..."

    terraform init \
        -upgrade \
        -reconfigure

    log_success "Terraform initialisé"
}

terraform_validate() {
    log "✅ Validation de la configuration Terraform..."

    terraform validate

    if [ $? -eq 0 ]; then
        log_success "Configuration Terraform valide"
    else
        log_error "Configuration Terraform invalide"
        exit 1
    fi
}

terraform_fmt() {
    log "🎨 Formatage des fichiers Terraform..."

    terraform fmt -recursive

    log_success "Fichiers formatés"
}

terraform_plan() {
    log "📋 Planification des changements..."

    local plan_file="terraform-plan-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S).tfplan"

    terraform plan \
        -var-file="$TERRAFORM_VARS_FILE" \
        -var="environment=$ENVIRONMENT" \
        -out="$plan_file" \
        ${TARGET:+-target="$TARGET"}

    log_success "Plan sauvegardé: $plan_file"
    export PLAN_FILE="$plan_file"
}

terraform_apply() {
    log "🚀 Application des changements..."

    # Sauvegarde de l'état si demandée
    if [ "$BACKUP" = "true" ]; then
        backup_state
    fi

    local apply_args=()

    if [ "$AUTO_APPROVE" = "true" ]; then
        apply_args+=("-auto-approve")
    fi

    if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
        terraform apply "${apply_args[@]}" "$PLAN_FILE"
    else
        terraform apply \
            "${apply_args[@]}" \
            -var-file="$TERRAFORM_VARS_FILE" \
            -var="environment=$ENVIRONMENT" \
            ${TARGET:+-target="$TARGET"}
    fi

    if [ $? -eq 0 ]; then
        log_success "Déploiement terminé avec succès!"
        show_deployment_info
    else
        log_error "Échec du déploiement"
        exit 1
    fi
}

terraform_destroy() {
    log "💥 Destruction de l'infrastructure..."

    # Confirmation pour la production
    if [ "$ENVIRONMENT" = "prod" ] && [ "$FORCE" != "true" ]; then
        log_warning "⚠️  ATTENTION: Destruction de l'environnement de PRODUCTION!"
        read -p "Tapez 'DELETE PROD' pour confirmer: " confirmation
        if [ "$confirmation" != "DELETE PROD" ]; then
            log_info "Destruction annulée"
            exit 0
        fi
    fi

    # Sauvegarde de l'état
    if [ "$BACKUP" = "true" ]; then
        backup_state
    fi

    local destroy_args=()

    if [ "$AUTO_APPROVE" = "true" ]; then
        destroy_args+=("-auto-approve")
    fi

    terraform destroy \
        "${destroy_args[@]}" \
        -var-file="$TERRAFORM_VARS_FILE" \
        -var="environment=$ENVIRONMENT" \
        ${TARGET:+-target="$TARGET"}

    if [ $? -eq 0 ]; then
        log_success "Infrastructure détruite"
    else
        log_error "Échec de la destruction"
        exit 1
    fi
}

terraform_output() {
    log "📊 Affichage des outputs..."

    terraform output -json | jq .
}

terraform_refresh() {
    log "🔄 Rafraîchissement de l'état..."

    terraform refresh \
        -var-file="$TERRAFORM_VARS_FILE" \
        -var="environment=$ENVIRONMENT"

    log_success "État rafraîchi"
}

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

backup_state() {
    log "💾 Sauvegarde de l'état Terraform..."

    mkdir -p "$STATE_BACKUP_DIR"

    local backup_file="$STATE_BACKUP_DIR/terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)"

    if [ -f "terraform.tfstate" ]; then
        cp terraform.tfstate "$backup_file"
        log_success "État sauvegardé: $backup_file"
    else
        log_warning "Aucun fichier d'état local trouvé"
    fi
}

show_deployment_info() {
    log "📋 Informations de déploiement:"

    echo ""
    echo -e "${GREEN}🎉 Déploiement réussi!${NC}"
    echo ""

    # Affichage des URLs importantes
    if terraform output -json &> /dev/null; then
        local outputs=$(terraform output -json)

        echo -e "${CYAN}🔗 URLs d'accès:${NC}"

        local app_url=$(echo "$outputs" | jq -r '.application_url.value // empty')
        if [ -n "$app_url" ] && [ "$app_url" != "null" ]; then
            echo "   Application: $app_url"
        fi

        local kibana_url=$(echo "$outputs" | jq -r '.kibana_url.value // empty')
        if [ -n "$kibana_url" ] && [ "$kibana_url" != "null" ]; then
            echo "   Kibana: $kibana_url"
        fi

        local eureka_url=$(echo "$outputs" | jq -r '.eureka_dashboard_url.value // empty')
        if [ -n "$eureka_url" ] && [ "$eureka_url" != "null" ]; then
            echo "   Eureka: $eureka_url (via tunnel SSH)"
        fi

        echo ""
        echo -e "${CYAN}💻 Connexions SSH:${NC}"

        local bastion_ip=$(echo "$outputs" | jq -r '.bastion_public_ip.value // empty')
        if [ -n "$bastion_ip" ] && [ "$bastion_ip" != "null" ]; then
            echo "   Bastion: ssh -i ~/.ssh/your-key.pem ubuntu@$bastion_ip"
        fi

        echo ""
        echo -e "${CYAN}📊 Commandes utiles:${NC}"
        echo "   terraform output          - Voir tous les outputs"
        echo "   ./scripts/post-deploy.sh  - Configuration post-déploiement"
        echo "   ./scripts/status.sh       - Vérifier le statut des services"
    fi

    echo ""
}

clean_temp_files() {
    log "🧹 Nettoyage des fichiers temporaires..."

    find . -name "*.tfplan" -mtime +7 -delete 2>/dev/null || true
    find . -name ".terraform.lock.hcl.backup*" -delete 2>/dev/null || true

    log_success "Nettoyage terminé"
}

# ============================================================================
# GESTION DES ARGUMENTS
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                export TF_LOG="INFO"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --auto-approve)
                AUTO_APPROVE="true"
                shift
                ;;
            --var-file)
                TERRAFORM_VARS_FILE="$2"
                shift 2
                ;;
            --target)
                TARGET="$2"
                shift 2
                ;;
            --backup)
                BACKUP="true"
                shift
                ;;
            plan|apply|destroy|validate|init|refresh|output|fmt|state|clean)
                ACTION="$1"
                shift
                ;;
            dev|staging|prod)
                ENVIRONMENT="$1"
                shift
                ;;
            *)
                log_error "Argument non reconnu: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# FONCTION PRINCIPALE
# ============================================================================

main() {
    show_banner

    parse_arguments "$@"

    log "🚀 Démarrage du déploiement"
    log "Action: $ACTION"
    log "Environment: $ENVIRONMENT"
    log "Terraform vars: $TERRAFORM_VARS_FILE"

    # Vérifications préalables
    check_dependencies
    check_aws_credentials
    check_environment
    check_terraform_files

    # Changement vers le répertoire Terraform
    cd "$TERRAFORM_DIR"

    # Exécution de l'action
    case "$ACTION" in
        init)
            terraform_init
            ;;
        validate)
            terraform_validate
            ;;
        fmt)
            terraform_fmt
            ;;
        plan)
            terraform_init
            terraform_validate
            terraform_plan
            ;;
        apply)
            terraform_init
            terraform_validate
            terraform_plan
            terraform_apply
            ;;
        destroy)
            terraform_destroy
            ;;
        refresh)
            terraform_refresh
            ;;
        output)
            terraform_output
            ;;
        clean)
            clean_temp_files
            ;;
        state)
            log "🗃️  Gestion de l'état Terraform"
            terraform state list
            ;;
        *)
            log_error "Action non reconnue: $ACTION"
            show_usage
            exit 1
            ;;
    esac

    log_success "Action '$ACTION' terminée avec succès"
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi