# Photo App Microservices

Ce projet est une application de gestion de photos construite avec une architecture microservices.

## Structure du Projet

Le projet est organisé en plusieurs modules microservices:

### 1. Service Utilisateurs (User Service)
- **Package**: `com.appsdeveloperblog.photoapp.api.users`
- **Description**: Gère l'authentification et les opérations CRUD des utilisateurs
- **Fonctionnalités principales**:
    - Création d'utilisateurs
    - Recherche d'utilisateurs par ID et email
    - Authentification avec Spring Security
    - Gestion des utilisateurs (liste, suppression)

## Prérequis
- Java 21
- Gradle 8.x
- Spring Boot 3.x## Architecture

L'application suit une architecture hexagonale (ports & adapters) avec:

### Couches principales:
- **Domain**: Contient les modèles et les règles métier
- **Application**: Contient les cas d'utilisation et la logique applicative
- **Infrastructure**: Gère la persistance et les adaptateurs externes

### Points d'entrée API REST:
- Création d'utilisateur: POST `/api/users`
- Recherche d'utilisateur: GET `/api/users/{id}`
- Liste des utilisateurs: GET `/api/users`
- Suppression d'utilisateur: DELETE `/api/users/{id}`

## Sécurité
L'application utilise Spring Security pour l'authentification et l'autorisation.

## Contact
Pour plus d'informations ou en cas de problèmes, veuillez créer une issue dans le repository.

## Configuration et Démarrage

### Service Utilisateurs
1. Naviguez vers le répertoire du service utilisateurs:
2. Construisez le projet avec Gradle:
3. Lancez l'application:

